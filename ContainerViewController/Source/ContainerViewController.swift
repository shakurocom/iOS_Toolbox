//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import UIKit

public extension UIViewController {
    var containerViewController: ContainerViewController? {
        return parent as? ContainerViewController
    }
}

public protocol ContainerViewControllerPresenting: class {
    func present(_ controller: UIViewController, style: ContainerViewController.TransitionStyle, animated: Bool)
}

public protocol ContainerViewControllerTransitionAnimator {
    func animate(fromView: UIView?, toView: UIView, contentView: UIView, didFinish: @escaping () -> Void)
}

/// A container view controller with animated transition support
public class ContainerViewController: UIViewController, ContainerViewControllerPresenting {

    public enum TransitionStyle {
        case push
        case pop
        case fade
        case custom(animator: ContainerViewControllerTransitionAnimator)
    }

    public private(set) var currentViewController: UIViewController?
    public private(set) var isOnScreen: Bool = false

    @IBOutlet public private(set) var contentView: UIView!

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
        contentView.clipsToBounds = true
    }

    public  override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isOnScreen = true
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isOnScreen = false
    }

    public final func present(_ controller: UIViewController, style: TransitionStyle, animated: Bool) {
        guard controller !== currentViewController else {
            return
        }
        willPresentViewController(controller, animated: animated)
        let actuallyOnScreen: Bool = isOnScreen
        let oldController: UIViewController? = currentViewController
        currentViewController = controller

        oldController?.willMove(toParent: nil)
        if actuallyOnScreen {
            oldController?.beginAppearanceTransition(false, animated: animated)
        }
        addChild(controller)
        if actuallyOnScreen {
            controller.beginAppearanceTransition(true, animated: animated)
        }

        let fromView: UIView? = oldController?.view

        let toView: UIView = controller.view
        toView.translatesAutoresizingMaskIntoConstraints = true
        toView.frame = contentView.bounds
        toView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.addSubview(toView)

        view.isUserInteractionEnabled = false
        let finishTransition: () -> Void = {
            if let actualOld: UIViewController = oldController {
                actualOld.view.removeFromSuperview()
                if actuallyOnScreen {
                    actualOld.endAppearanceTransition()
                }
                actualOld.removeFromParent()
            }
            if actuallyOnScreen {
                controller.endAppearanceTransition()
            }
            controller.didMove(toParent: self)
            self.view.isUserInteractionEnabled = true
            self.didPresentViewController(controller, animated: animated)
        }

        if animated {
            switch (style, fromView) {
            case (.push, .some(let actualFromView)):
                animatePushPop(fromView: actualFromView, toView: toView, push: true, didFinish: finishTransition)
            case (.pop, .some(let actualFromView)):
                animatePushPop(fromView: actualFromView, toView: toView, push: false, didFinish: finishTransition)
            case (.fade, _):
                animateFade(fromView: nil, toView: toView, didFinish: finishTransition)
            case (.custom(let animator), _):
                animator.animate(fromView: fromView, toView: toView, contentView: contentView, didFinish: finishTransition)
            default:
                animateFade(fromView: nil, toView: toView, didFinish: finishTransition)
            }
        } else {
            finishTransition()
        }
    }

    // MARK: - Override

    public func willPresentViewController(_ controller: UIViewController, animated: Bool) {}
    public func didPresentViewController(_ controller: UIViewController, animated: Bool) {}

}

// MARK: - Private

private extension ContainerViewController {

    func animatePushPop(fromView: UIView, toView: UIView, push: Bool, didFinish: @escaping () -> Void) {
        let contentSizeWidth: CGFloat = contentView.bounds.size.width
        let toViewTransform: CGAffineTransform
        let fromViewTransform: CGAffineTransform
        if push {
            toViewTransform = CGAffineTransform(translationX: contentSizeWidth, y: 0)
            fromViewTransform = CGAffineTransform(translationX: -contentSizeWidth * 0.3, y: 0)
        } else {
            toViewTransform = CGAffineTransform(translationX: -contentSizeWidth * 0.3, y: 0)
            fromViewTransform = CGAffineTransform(translationX: contentSizeWidth, y: 0)
            contentView.sendSubviewToBack(toView)
        }
        toView.transform = toViewTransform
        UIView.animate(withDuration: 0.33, delay: 0.0, options: [.curveEaseOut], animations: {
            toView.transform = CGAffineTransform.identity
            fromView.transform = fromViewTransform
        }, completion: { (_) in
            fromView.transform = CGAffineTransform.identity
            didFinish()
        })
    }

    func animateFade(fromView: UIView?, toView: UIView, didFinish: @escaping () -> Void) {
        toView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            fromView?.alpha = 0.0
            toView.alpha = 1.0
        }, completion: { (_) in
            didFinish()
        })
    }
}
