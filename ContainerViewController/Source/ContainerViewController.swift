//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import UIKit

public extension UIViewController {

    /// If the recipient is a child of a ContainerViewController, this property holds the view controller it is contained in.
    var containerViewController: ContainerViewController? {
        return parent as? ContainerViewController
    }
}

public protocol ContainerViewControllerPresenting: class {
    func present(_ controller: UIViewController, style: ContainerViewController.TransitionStyle, animated: Bool)
}

/// Custom Animator support
public protocol ContainerViewControllerTransitionAnimator {

    /// Will be called by the ContainerViewController during animated transition
    ///
    /// - Parameters:
    ///   - fromView: Old content view or nil
    ///   - toView: New content view to display
    ///   - containerView: The container view where content view is placed
    ///   - didFinish: A closure to be executed when the transition ends. 
    func animate(fromView: UIView?, toView: UIView, containerView: UIView, didFinish: @escaping () -> Void)
}

/// A container view controller with animated transition support
public class ContainerViewController: UIViewController, ContainerViewControllerPresenting {

    /// The type of transition animation
    public enum TransitionStyle {
        case push
        case pop
        case fade
        case custom(animator: ContainerViewControllerTransitionAnimator)
    }

    /// The view controller that is presented by this view controller or nil
    public private(set) var currentViewController: UIViewController?

    /// Indicates that the controller is currently on the screen
    public private(set) var isOnScreen: Bool = false

    /// The super view for currentViewController.view
    @IBOutlet public private(set) var containerView: UIView!

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
        containerView.clipsToBounds = true
    }

    public  override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isOnScreen = true
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isOnScreen = false
    }

    /// Performs transition to the new view controller
    ///
    /// - Parameters:
    ///   - controller: The view controller that will be presented
    ///   - style: The type of transition animation
    ///   - animated: Perform or do not perform animation during transition
    public final func present(_ newController: UIViewController, style: TransitionStyle, animated: Bool) {
        guard newController !== currentViewController else {
            return
        }
        willPresentViewController(newController, animated: animated)
        let actuallyOnScreen: Bool = isOnScreen
        let oldController: UIViewController? = currentViewController
        currentViewController = newController

        oldController?.willMove(toParent: nil)
        if actuallyOnScreen {
            oldController?.beginAppearanceTransition(false, animated: animated)
        }
        addChild(newController)
        if actuallyOnScreen {
            newController.beginAppearanceTransition(true, animated: animated)
        }

        let fromView: UIView? = oldController?.view

        let toView: UIView = newController.view
        toView.translatesAutoresizingMaskIntoConstraints = true
        toView.frame = containerView.bounds
        toView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        containerView.addSubview(toView)

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
                newController.endAppearanceTransition()
            }
            newController.didMove(toParent: self)
            self.view.isUserInteractionEnabled = true
            self.didPresentViewController(newController, animated: animated)
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
                animator.animate(fromView: fromView, toView: toView, containerView: containerView, didFinish: finishTransition)
            default:
                finishTransition()
            }
        } else {
            finishTransition()
        }
    }

    // MARK: - Override

    /// Will be performed directly before transition
    ///
    /// - Parameters:
    ///   - controller: The view controller that will be presented
    ///   - animated: true if transition is animated, false otherwise
    public func willPresentViewController(_ controller: UIViewController, animated: Bool) {}

    /// Will be performed when the transition ends.
    ///
    /// - Parameters:
    ///   - controller: The view controller that will be presented
    ///   - animated: true if transition was animated, false otherwise
    public func didPresentViewController(_ controller: UIViewController, animated: Bool) {}

}

// MARK: - Private

private extension ContainerViewController {

    func animatePushPop(fromView: UIView, toView: UIView, push: Bool, didFinish: @escaping () -> Void) {
        let contentSizeWidth: CGFloat = containerView.bounds.size.width
        let toViewTransform: CGAffineTransform
        let fromViewTransform: CGAffineTransform
        if push {
            toViewTransform = CGAffineTransform(translationX: contentSizeWidth, y: 0)
            fromViewTransform = CGAffineTransform(translationX: -contentSizeWidth * 0.3, y: 0)
        } else {
            toViewTransform = CGAffineTransform(translationX: -contentSizeWidth * 0.3, y: 0)
            fromViewTransform = CGAffineTransform(translationX: contentSizeWidth, y: 0)
            containerView.sendSubviewToBack(toView)
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
