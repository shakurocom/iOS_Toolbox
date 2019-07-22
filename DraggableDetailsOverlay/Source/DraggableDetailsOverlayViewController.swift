//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import UIKit
//TODO: 58: bounces
//TODO: 58: handle
//TODO: 58: hide by drag down offscreen
//
//internal protocol DraggableDetailsOverlayContainerInterface: class {
//    func scrollViewDidScroll(_ scrollView: UIScrollView)
//    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
//    func checkVisibility(of subview: UIView) -> Bool
//    func changeToState(_ newState: DraggableDetailsOverlayViewController.State, animated: Bool)
//    func removeOverlayFromParentViewController()
//}
//
//internal protocol DraggableDetailsOverlayNestedInterface {
//    var containerController: DraggableDetailsOverlayContainerInterface? { get set }
//
//    func contentSizeForMiddleState() -> CGFloat
//    func contentHeaderView() -> UIView
//    func contentMainView() -> UIView
//    func contentMainScrollView() -> UIScrollView?
//
//    func stateDidChange(newState: DraggableDetailsOverlayViewController.State)
//}

public protocol DraggableDetailsOverlayViewControllerDelegate: class {
    func draggableDetailsOverlayAnchors(_ overlay: DraggableDetailsOverlayViewController) -> [DraggableDetailsOverlayViewController.Anchor]
}

public class DraggableDetailsOverlayViewController: UIViewController {

    public typealias NestedConstroller = UIViewController

    public enum Anchor {
        case top(offset: CGFloat)
        case middle(height: CGFloat)
    }

    private enum Constant {
        static let hiddenContainerOffset: CGFloat = 10
        static let showHideAnimationDuration: TimeInterval = 0.25
        static let snapAnimationDuration: TimeInterval = 0.2
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

//    private enum Constant {
//        static let springAnimationDuration: TimeInterval = 0.4
//        static let plainAnimationDuration: TimeInterval = 0.2
//    }
//
//    internal private(set) var state: State = .hidden
//    private var availableStates: [State] = [.hidden, .onScreenBottom, .onScreenMiddle, .onScreenFull]
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
    private var cachedAnchorOffsetsForHeight: CGFloat = 0 // height for which offsets were cached

//    private var isDragInScroll: Bool = false
//    private var preventContentScroll: Bool = false
//    private var currentContentScrollOffset: CGPoint = CGPoint.zero

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

//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        if let contentScrollView = nestedController.contentMainScrollView() {
//            currentContentScrollOffset = contentScrollView.contentOffset
//        }
//
//        updateLayout(state: .hidden, animated: false)
//    }
//
//    // MARK: - Public
//
//    internal func changeToState(_ newState: State, animated: Bool) {
//        state = newState
//        updateLayout(state: newState, animated: animated, completion: {
//            self.nestedController.stateDidChange(newState: self.state)
//        })
//    }
//
//    func offsetForState(_ targetState: State) -> CGFloat {
//        let result: CGFloat
//        switch targetState {
//        case .hidden:
//            result = view.bounds.height + 10 // just a little bigger
//        case .onScreenBottom:
//            result = view.bounds.height -
//                dragHandleContainerView.bounds.height -
//                contentHeaderContainerView.bounds.height -
//                bottomSafeAreaInset()
//        case .onScreenMiddle:
//            result = max(view.bounds.height -
//                dragHandleContainerView.bounds.height -
//                contentHeaderContainerView.bounds.height -
//                nestedController.contentSizeForMiddleState() -
//                bottomSafeAreaInset(),
//                         0.0)
//        case .onScreenFull:
//            result = topAncorOffset
//        }
//        return result
//    }
//
//    // MARK: - Private
//
//    private func updateLayout(state: State, animated: Bool, completion: (() -> Void)? = nil) {
//        draggableContainerTopConstraint.constant = offsetForState(state)
//        if animated {
//            draggableContainerView.isHidden = false
//            if state == .onScreenMiddle || state == .onScreenBottom {
//                UIView.animate(
//                    withDuration: Constant.springAnimationDuration,
//                    delay: 0.0,
//                    usingSpringWithDamping: 0.7,
//                    initialSpringVelocity: 1.5,
//                    options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
//                    animations: {
//                        self.view.layoutIfNeeded()
//                },
//                    completion: { (_) in
//                        completion?()
//                })
//            } else {
//                UIView.animate(
//                    withDuration: Constant.plainAnimationDuration,
//                    delay: 0.0,
//                    options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
//                    animations: {
//                        self.view.layoutIfNeeded()
//                },
//                    completion: { (finished: Bool) -> Void in
//                        if finished {
//                            self.draggableContainerView.isHidden = self.state == .hidden
//                        }
//                        completion?()
//                })
//            }
//        } else {
//            draggableContainerView.isHidden = state == .hidden
//            completion?()
//        }
//    }
//
//
//    private func stateForOffset(_ offset: CGFloat) -> State {
//        let states: [State] = availableStates
//        for (index, state) in states.enumerated() {
//            let offsetForCurrentState = offsetForState(state)
//            if index == 0 {
//                let borderPointBottom = offsetForCurrentState
//                let borderPointTop = offsetForCurrentState - (offsetForCurrentState - offsetForState(states[index + 1])) / 2.0
//                if offset > borderPointTop && offset <= borderPointBottom {
//                    return state
//                }
//            } else if index == states.count - 1 {
//                let borderPointBottom = offsetForCurrentState + (offsetForState(states[index - 1]) - offsetForCurrentState) / 2.0
//                let borderPointTop = offsetForCurrentState
//                if offset >= borderPointTop && offset < borderPointBottom {
//                    return state
//                }
//            } else {
//                let borderPointBottom = offsetForCurrentState + (offsetForState(states[index - 1]) - offsetForCurrentState) / 2.0
//                let borderPointTop = offsetForCurrentState - (offsetForCurrentState - offsetForState(states[index + 1])) / 2.0
//                if offset > borderPointTop && offset <= borderPointBottom {
//                    return state
//                }
//            }
//        }
//        return .hidden
//    }
//
//    private func setPreventContentScroll(_ newValue: Bool) {
//        preventContentScroll = newValue
//        guard let contentScrollView = nestedController.contentMainScrollView() else {
//            return
//        }
//        contentScrollView.showsVerticalScrollIndicator = !newValue
//        if newValue {
//            currentContentScrollOffset = contentScrollView.contentOffset
//        }
//    }
//
}

// MARK: - UIGestureRecognizerDelegate

extension DraggableDetailsOverlayViewController: UIGestureRecognizerDelegate {

//    private func isContentScrollAtTop() -> Bool {
//        if let contentScrollview = nestedController.contentMainScrollView() {
//            return contentScrollview.contentOffset.y <= -contentScrollview.contentInset.top
//        }
//        return true
//    }

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
//            if dragGestureRecognizer.numberOfTouches > 0, let contentScrollView = nestedController.contentMainScrollView() {
//                let touchLocation = dragGestureRecognizer.location(ofTouch: 0, in: contentScrollView.superview)
//                if contentScrollView.frame.contains(touchLocation) {
//                    isDragInScroll = true
//                    setPreventContentScroll(true)
//                }
//            }
            //TODO: 58:
            break

        case .changed:
//            if draggableContainerTopConstraint.constant != topAncorOffset || isContentScrollAtTop() || !isDragInScroll {
                let newOffset = draggableContainerShownTopConstraint.constant + translationY
                let maxOffset = cachedAnchorOffsets.last ?? 0
                let minOffset = cachedAnchorOffsets.first ?? 0
//                let preventContentScroll: Bool
                switch newOffset {
                case ..<minOffset:
                    draggableContainerShownTopConstraint.constant = minOffset
//                    preventContentScroll = false
//
                case minOffset...maxOffset:
                    draggableContainerShownTopConstraint.constant = newOffset
//                    preventContentScroll = true
//
                case maxOffset...:
                    draggableContainerShownTopConstraint.constant = maxOffset
//                    preventContentScroll = true
//
                default:
                    //this should not be happening
                    break
//                    preventContentScroll = false
                }
//                setPreventContentScroll(preventContentScroll)
//            } else {
//                setPreventContentScroll(false)
//            }

        case .ended,
             .cancelled,
             .failed:
            let deceleratedOffset = DecelerationHelper.project(value: draggableContainerShownTopConstraint.constant,
                                                               initialVelocity: velocity.y / 1000.0, // should be in milliseconds
                                                               decelerationRate: Constant.decelerationRate.rawValue)
            let restOffset = closestAnchorOffsetForOffset(deceleratedOffset)
            if draggableContainerShownTopConstraint.constant != restOffset {
                animateToOffset(restOffset)
            }
//            let canChangeState = state != .hidden && (state != bottomAncorState || velocityY < 0) &&
//                (draggableContainerTopConstraint.constant != topAncorOffset || isContentScrollAtTop()) &&
//                abs(velocityY) > Constant.changeStateVelocityThreshold
//            let currentState = stateForOffset(draggableContainerTopConstraint.constant)
//            if canChangeState, let currentStateIndex = availableStates.firstIndex(of: currentState) {
//                let previousState: State = currentStateIndex - 1 >= 0 ? availableStates[currentStateIndex - 1] : currentState
//                let nextState: State = currentStateIndex + 1 < availableStates.count ? availableStates[currentStateIndex + 1] : currentState
//                let newState: State = velocityY < 0 ? nextState : previousState
//                changeToState(newState, animated: true)
//            } else {
//                changeToState(stateForOffset(draggableContainerTopConstraint.constant), animated: true)
//            }
//            DispatchQueue.main.async(execute: {
//                self.setPreventContentScroll(false)
//            })
//            isDragInScroll = false

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

    private func animateToOffset(_ targetOffset: CGFloat) {
        UIView.animate(
            withDuration: Constant.snapAnimationDuration,
            delay: 0.0,
            options: [.beginFromCurrentState],
            animations: {
                self.draggableContainerShownTopConstraint.constant = targetOffset
                self.view.layoutIfNeeded()
        },
            completion: nil)
    }

}

//// MARK: - DraggableDetailsOverlayContainerInterface
//
//extension DraggableDetailsOverlayViewController: DraggableDetailsOverlayContainerInterface {
//
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if preventContentScroll {
//            scrollView.contentOffset = currentContentScrollOffset
//        }
//    }
//
//    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        if preventContentScroll {
//            targetContentOffset.pointee = currentContentScrollOffset
//        }
//    }
//
//    func checkVisibility(of subview: UIView) -> Bool {
//        let frame = view.convert(subview.bounds, from: subview)
//        return view.bounds.intersects(frame)
//    }
//
//}
