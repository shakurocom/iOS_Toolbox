//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import UIKit

//TODO: 58: bounces
//TODO: 58: handle
//TODO: 58: hide by drag down offscreen
//TODO: 58: top uncoverable area
//TODO: 58: max height
//TODO: 58: is visible state
//TODO: 58: configure deceleration rate
//TODO: 58: forbid to skip next anchor on "deceleration"
/**
 Delegate of the draggable overlay. The one whole controls it.
 */
public protocol DraggableDetailsOverlayViewControllerDelegate: class {
    func draggableDetailsOverlayAnchors(_ overlay: DraggableDetailsOverlayViewController) -> [DraggableDetailsOverlayViewController.Anchor]
    // TODO: 58: did drag
    // TODO: 58: did end dragging
}

/**
 Interface for controller, that will be displayed inside draggable overlay.
 */
public protocol DraggableDetailsOverlayNestedInterface {
    /**
     - parameter requirePreventOfScroll: `true` indicates that overlay is currently dragging.
            Nested controller should prevent any content scrolling.
            For better UX scrolling indicators should be disabled as well.
            methods to be aware of are:
            1) func scrollViewDidScroll(_:) - keep offset at saved value
            2) func scrollViewWillEndDragging(_:,withVelocity:,targetContentOffset:) - set targetContentOffset.pointee to saved offset
     */
    func draggableDetailsOverlay(_ overlay: DraggableDetailsOverlayViewController, requirePreventOfScroll: Bool)
    func draggableDetailsOverlayContentScrollViews(_ overlay: DraggableDetailsOverlayViewController) -> [UIScrollView]
}

public class DraggableDetailsOverlayViewController: UIViewController {

    public typealias NestedConstroller = UIViewController & DraggableDetailsOverlayNestedInterface

    public enum Anchor {
        case top(offset: CGFloat)
        case middle(height: CGFloat)
    }

    private enum Constant {
        static let hiddenContainerOffset: CGFloat = 10
        static let showHideAnimationDuration: TimeInterval = 0.25
        static let decelerationRate: UIScrollView.DecelerationRate = .normal
    }

    public var isShadowEnabled: Bool = true { //TODO: 58: example
        didSet {
            guard isViewLoaded else { return }
            shadowBackgroundView.isHidden = !isShadowEnabled
        }
    }

    public var shadowBackgroundColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5) { //TODO: 58: example
        didSet {
            guard isViewLoaded else { return }
            shadowBackgroundView.backgroundColor = shadowBackgroundColor
        }
    }

    public var draggableContainerBackgroundColor: UIColor = UIColor.white { //TODO: 58: example
        didSet {
            guard isViewLoaded else { return }
            draggableContainerView.backgroundColor = draggableContainerBackgroundColor
        }
    }

    public var isDraggableContainerRoundedTopCornersEnabled: Bool = false { //TODO: 58: example
        didSet {
            guard isViewLoaded else { return }
            draggableContainerView.isRoundedTopCornersEnabled = isDraggableContainerRoundedTopCornersEnabled
        }
    }

    public var draggableContainerTopCornersRadius: CGFloat = 5 { //TODO: 58: example
        didSet {
            guard isViewLoaded else { return }
            draggableContainerView.topCornersRadius = draggableContainerTopCornersRadius
        }
    }

    /**
     Duration of animation used, when user releases finger during drag.
     Default value is 0.2 .
     */
    public var snapAnimationNormalDuration: TimeInterval = 0.2 //TODO: 58: example

    /**
     Use spring animation for snapping to anchors.
     Default value is `true`.
     */
    public var snapAnimationUseSpring: Bool = true //TODO: 58: example

    /**
     Same as `snapAnimationUseSpring`, but explicitly for top anchor.
     Default value is `false`.
     */
    public var snapAnimationTopAnchorUseSpring: Bool = false //TODO: 58: example

    /**
     Duration of animation used, when user releases finger during drag and container snaps to anchor.
     Default value is 0.4 .
     */
    public var snapAnimationSpringDuration: TimeInterval = 0.4 //TODO: 58: example

    /**
     Parameter of spring animation (if enabled).
     Default value is 0.7 .
     */
    public var snapAnimationSpringDamping: CGFloat = 0.7 //TODO: 58: example

    /**
     Parameter of spring animation (if enabled).
     Default value is 1.5 .
     */
    public var snapAnimationSpringInitialVelocity: CGFloat = 1.5 //TODO: 58: example

    private var shadowBackgroundView: UIView!
    private var draggableContainerView: DraggableDetailsOverlayContainerView!
    private var draggableContainerHiddenTopConstraint: NSLayoutConstraint!
    private var draggableContainerShownTopConstraint: NSLayoutConstraint!
    private var draggableContainerHeightConstraint: NSLayoutConstraint!
    private var dragGestureRecognizer: UIPanGestureRecognizer!

    private let nestedController: NestedConstroller
    private weak var delegate: DraggableDetailsOverlayViewControllerDelegate?

    private var anchors: [Anchor] = []
    private var cachedAnchorOffsets: [CGFloat] = [0]
    /**
     Height for which offsets were cached.
     */
    private var cachedAnchorOffsetsForHeight: CGFloat = 0

    /**
     Scroll view from nested content, where pan started.
     Downward drag is disabled if this scroll is not at the top of it's content.
     */
    private var currentPanStartingContentScrollView: UIScrollView?

    // MARK: - Initialization

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not allowed. Use init(style:)")
    }

    public init(nestedController: NestedConstroller, delegate: DraggableDetailsOverlayViewControllerDelegate) {
        self.nestedController = nestedController
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    override public func loadView() {
        // some solid frame to operate with constraints
        let mainView = TouchTransparentView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        mainView.backgroundColor = UIColor.clear
        mainView.clipsToBounds = true
        view = mainView

        setupShadowBackgroundView(mainView: mainView)
        setupDraggableContainer(mainView: mainView)
        setupPanRecognizer(mainView: mainView)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addToContainerChildViewController(nestedController, targetContainerView: draggableContainerView)
    }

    // MARK: - Events

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.bounds.height != cachedAnchorOffsetsForHeight {
            updateAnchors()
            cachedAnchorOffsetsForHeight = view.bounds.height
        }
    }

    // MARK: - Public

    public func show(initialAnchor: Anchor, animated: Bool) {
        setVisible(true, animated: animated, initialAnchor: initialAnchor)
    }

    public func hide(animated: Bool) {
        setVisible(false, animated: animated, initialAnchor: .top(offset: 0))
    }

}

// MARK: - UIGestureRecognizerDelegate

extension DraggableDetailsOverlayViewController: UIGestureRecognizerDelegate {

    @objc private func handleDragGesture(_ recognizer: UIGestureRecognizer) {
        guard recognizer === dragGestureRecognizer, !view.isHidden else {
            return
        }
        let translationY: CGFloat = dragGestureRecognizer.translation(in: dragGestureRecognizer.view).y
        let velocity = dragGestureRecognizer.velocity(in: dragGestureRecognizer.view)
        dragGestureRecognizer.setTranslation(CGPoint.zero, in: dragGestureRecognizer.view)
        switch recognizer.state {
        case .possible:
            break

        case .began:
            let contentScrollViews = nestedController.draggableDetailsOverlayContentScrollViews(self)
            currentPanStartingContentScrollView = contentScrollViews.first(where: { (scroll) -> Bool in
                let touchLocation = dragGestureRecognizer.location(ofTouch: 0, in: scroll.superview)
                return scroll.frame.contains(touchLocation)
            })
            setPreventContentScroll(true)

        case .changed:
            if isContentScrollAtTop(contentScrollView: currentPanStartingContentScrollView) || translationY < 0 {
                let newOffset = draggableContainerShownTopConstraint.constant + translationY
                let maxOffset = cachedAnchorOffsets.last ?? 0
                let minOffset = cachedAnchorOffsets.first ?? 0
                if newOffset < minOffset {
                    draggableContainerShownTopConstraint.constant = minOffset
                    setPreventContentScroll(false)
                } else if minOffset <= newOffset && newOffset <= maxOffset {
                    draggableContainerShownTopConstraint.constant = newOffset
                    setPreventContentScroll(true)
                } else { // newOffset > maxOffset
                    draggableContainerShownTopConstraint.constant = maxOffset
                    setPreventContentScroll(false)
                }
            } else {
                setPreventContentScroll(false)
            }

        case .ended,
             .cancelled,
             .failed:
            let deceleratedOffset = DecelerationHelper.project(value: draggableContainerShownTopConstraint.constant,
                                                               initialVelocity: velocity.y / 1000.0, // should be in milliseconds
                                                               decelerationRate: Constant.decelerationRate.rawValue)
            let restOffset = closestAnchorOffsetForOffset(deceleratedOffset)
            if draggableContainerShownTopConstraint.constant != restOffset {
                let isSpring = restOffset == cachedAnchorOffsets.first ? snapAnimationTopAnchorUseSpring : snapAnimationUseSpring
                animateToOffset(restOffset, isSpring: isSpring)
            }
            currentPanStartingContentScrollView = nil
            DispatchQueue.main.async(execute: {
                self.setPreventContentScroll(false)
            })

        @unknown default:
            break
        }
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !view.isHidden else {
            return false
        }
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        //TODO: 58: add scroll to exmaple - test this
        if gestureRecognizer === dragGestureRecognizer || otherGestureRecognizer === dragGestureRecognizer {
            return true
        }
        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === dragGestureRecognizer,
            !view.isHidden,
            isShadowEnabled || draggableContainerView.frame.contains(touch.location(in: view))
            else {
                return false
        }
        return true
    }

}

// MARK: - Private

private extension DraggableDetailsOverlayViewController {

    private func setupShadowBackgroundView(mainView: UIView) {
        shadowBackgroundView = UIView(frame: mainView.bounds)
        shadowBackgroundView.backgroundColor = shadowBackgroundColor
        shadowBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(shadowBackgroundView)
        shadowBackgroundView.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        shadowBackgroundView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        shadowBackgroundView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
        shadowBackgroundView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        shadowBackgroundView.isHidden = !isShadowEnabled
    }

    private func setupDraggableContainer(mainView: UIView) {
        draggableContainerView = DraggableDetailsOverlayContainerView(frame: mainView.bounds)
        draggableContainerView.backgroundColor = draggableContainerBackgroundColor
        draggableContainerView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(draggableContainerView)
        if #available(iOS 11.0, *) {
            draggableContainerShownTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: mainView.safeAreaLayoutGuide.topAnchor)
            draggableContainerHiddenTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: mainView.bottomAnchor,
                                                                                                constant: Constant.hiddenContainerOffset)
        } else {
            draggableContainerShownTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor)
            draggableContainerHiddenTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: mainView.bottomAnchor,
                                                                                                constant: Constant.hiddenContainerOffset)
        }
        draggableContainerShownTopConstraint.isActive = false
        draggableContainerHiddenTopConstraint.isActive = true
        draggableContainerHeightConstraint = draggableContainerView.heightAnchor.constraint(equalTo: mainView.heightAnchor,
                                                                                            constant: 0) //TODO: 58: delegate
        draggableContainerHeightConstraint.isActive = true
        draggableContainerView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 0).isActive = true
        draggableContainerView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: 0).isActive = true
        draggableContainerView.isRoundedTopCornersEnabled = isDraggableContainerRoundedTopCornersEnabled
        draggableContainerView.topCornersRadius = draggableContainerTopCornersRadius
    }

    private func setupPanRecognizer(mainView: UIView) {
        dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragGesture))
        dragGestureRecognizer.delegate = self
        dragGestureRecognizer.isEnabled = true
        mainView.addGestureRecognizer(dragGestureRecognizer)
    }

    private func updateAnchors() {
        anchors = delegate?.draggableDetailsOverlayAnchors(self) ?? [.top(offset: 0)]
        var newOffsets: [CGFloat] = []
        for anchor in anchors {
            let offset = offsetForAnchor(anchor)
            // ignore very small steps
            if !newOffsets.contains(where: { return abs($0 - offset) < 1.0 }) {
                newOffsets.append(offset)
            }
        }
        cachedAnchorOffsets = newOffsets.sorted(by: { $0 < $1 })
    }

    private func offsetForAnchor(_ anchor: Anchor) -> CGFloat {
        switch anchor {
        case .top(let uncoverableOffset):
            return uncoverableOffset
        case .middle(let containerHeight):
            return max(0, view.bounds.height - containerHeight - bottomSafeAreaInset())
        }
    }

    private func closestAnchorOffsetForOffset(_ targetOffset: CGFloat) -> CGFloat {
        return cachedAnchorOffsets.min(by: { return abs($0 - targetOffset) < abs($1 - targetOffset)}) ?? 0
    }

    private func bottomSafeAreaInset() -> CGFloat {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets.bottom
        } else {
            return bottomLayoutGuide.length
        }
    }

    private func setVisible(_ newVisible: Bool, animated: Bool, initialAnchor: Anchor) {
        let initialOffset: CGFloat
        if newVisible {
            updateAnchors()
            view.isHidden = false
            let wantedOffset = offsetForAnchor(initialAnchor)
            initialOffset = closestAnchorOffsetForOffset(wantedOffset)
        } else {
            initialOffset = 0
        }
        let animations = { () -> Void in
            if newVisible {
                self.shadowBackgroundView.alpha = 1.0
                self.draggableContainerHiddenTopConstraint.isActive = false
                self.draggableContainerShownTopConstraint.constant = initialOffset
                self.draggableContainerShownTopConstraint.isActive = true
            } else {
                self.shadowBackgroundView.alpha = 0.0
                self.draggableContainerShownTopConstraint.isActive = false
                self.draggableContainerHiddenTopConstraint.isActive = true
            }
        }
        let completion = { (finished: Bool) -> Void in
            if finished && !newVisible {
                self.view.isHidden = true
            }
        }
        if animated {
            UIView.animate(
                withDuration: Constant.showHideAnimationDuration,
                delay: 0.0,
                options: [.beginFromCurrentState],
                animations: {
                    animations()
                    self.view.layoutIfNeeded()
            },
                completion: completion)
        } else {
            animations()
            completion(true)
        }
    }

    private func animateToOffset(_ targetOffset: CGFloat, isSpring: Bool) {
        let animations = { () -> Void in
            self.draggableContainerShownTopConstraint.constant = targetOffset
            self.view.layoutIfNeeded()
        }
        if isSpring {
            UIView.animate(withDuration: snapAnimationSpringDuration,
                           delay: 0.0,
                           usingSpringWithDamping: snapAnimationSpringDamping,
                           initialSpringVelocity: snapAnimationSpringInitialVelocity,
                           options: [.beginFromCurrentState],
                           animations: animations,
                           completion: nil)
        }
        UIView.animate(withDuration: snapAnimationNormalDuration,
                       delay: 0.0,
                       options: [.beginFromCurrentState],
                       animations: animations,
                       completion: nil)
    }

    private func setPreventContentScroll(_ newValue: Bool) {
        nestedController.draggableDetailsOverlay(self, requirePreventOfScroll: newValue)
    }

    private func isContentScrollAtTop(contentScrollView: UIScrollView?) -> Bool {
        guard let scroll = contentScrollView else {
            return true
        }
        return scroll.contentOffset.y <= -scroll.contentInset.top
    }

}
