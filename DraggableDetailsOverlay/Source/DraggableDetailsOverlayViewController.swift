//
//
//

import Foundation
import UIKit

//internal struct DraggableDetailsOverlayStyle {
//    internal var backgroundColor: UIColor = UIColor.white
//    internal var cornerRadius: CGFloat = 0.0
//    internal var handleContainerHeight: CGFloat = 10.0
//    internal var handleSize: CGSize = CGSize(width: 50.0, height: 5.0)
//    internal var handleColor: UIColor = UIColor.blue
//}
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
//
///*
// add similar instruction and a helper method
// self.loginView = [self.storyboard instantiateViewControllerWithIdentifier:@"LOGIN"];
// [self addChildViewController:self.loginView];
// [self.loginView.view setFrame:CGRectMake(0.0f, 0.0f, self.contentView.frame.size.width, self.contentView.frame.size.height)];
// [self.contentView addSubview:self.loginView.view];
// [self.loginView didMoveToParentViewController:self];
// */
//
///**
// */
public class DraggableDetailsOverlayViewController: UIViewController {

    public typealias NestedConstroller = UIViewController

//    private enum Constant {
//        static let changeStateVelocityThreshold: CGFloat = 1000.0
//        static let springAnimationDuration: TimeInterval = 0.4
//        static let plainAnimationDuration: TimeInterval = 0.2
//    }
//
//    internal private(set) var state: State = .hidden
//    private var availableStates: [State] = [.hidden, .onScreenBottom, .onScreenMiddle, .onScreenFull]
//    private var showBackground: Bool = false
//    private var bottomAncorState: State = .hidden
//    private var topAncorOffset: CGFloat = 0.0
//
//    private var draggableContainerView: UIView!
//    private var draggableContainerTopConstraint: NSLayoutConstraint!
//    private var dragHandleContainerView: UIView!
//    private var dragHandleView: UIView!
//    private var contentHeaderContainerView: UIView!
//    private var contentMainContainerView: UIView!
//
//    private var dragGestureRecognizer: UIPanGestureRecognizer!
//
//    private let style: DraggableDetailsOverlayStyle
//    private var isDragInScroll: Bool = false
//    private var preventContentScroll: Bool = false
//    private var currentContentScrollOffset: CGPoint = CGPoint.zero

    private let nestedController: NestedConstroller

    // MARK: - Initialization

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not allowed. Use init(style:)")
    }

    public init(nestedController: NestedConstroller) {
        self.nestedController = nestedController
        super.init(nibName: nil, bundle: nil)
    }

    override public func loadView() {
        // some solid frame to operate with constraints
        let mainView = TouchTransparentView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        mainView.backgroundColor = UIColor.green.withAlphaComponent(0.4) //TODO: 58:
        view = mainView

//        setupDraggableContainer(mainView: mainView)
//        setupDragHandle()
//        setupHeader()
//        setupContent()
//
//        dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragGesture))
//        dragGestureRecognizer.delegate = self
//        draggableContainerView.addGestureRecognizer(dragGestureRecognizer)

    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        //TODO: overlay.addToContainerChildViewController(nestedController, targetContainerView: nil) //TODO: 58:
    }

    // MARK: - Public

//
//    private func setupDraggableContainer(mainView: UIView) {
//        draggableContainerView = UIView(frame: mainView.bounds)
//        draggableContainerView.backgroundColor = style.backgroundColor
//        draggableContainerView.translatesAutoresizingMaskIntoConstraints = false
//        mainView.addSubview(draggableContainerView)
//        draggableContainerTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 0)
//        draggableContainerTopConstraint.isActive = true
//        draggableContainerView.heightAnchor.constraint(equalTo: mainView.heightAnchor, constant: -topAncorOffset).isActive = true
//        draggableContainerView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 0).isActive = true
//        draggableContainerView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: 0).isActive = true
//    }
//
//    private func setupDragHandle() {
//        dragHandleContainerView = UIView(frame: CGRect(x: 0, y: 0, width: draggableContainerView.bounds.width, height: style.handleContainerHeight))
//        dragHandleContainerView.backgroundColor = style.backgroundColor
//        dragHandleContainerView.translatesAutoresizingMaskIntoConstraints = true
//        dragHandleContainerView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
//        draggableContainerView.addSubview(dragHandleContainerView)
//
//        dragHandleView = UIView(frame: CGRect(x: 0, y: 0, width: style.handleSize.width, height: style.handleSize.height))
//        dragHandleView.backgroundColor = style.handleColor
//        dragHandleView.layer.cornerRadius = style.handleSize.height / 2.0
//        dragHandleView.translatesAutoresizingMaskIntoConstraints = false
//        dragHandleContainerView.addSubview(dragHandleView)
//        dragHandleView.widthAnchor.constraint(equalToConstant: style.handleSize.width).isActive = true
//        dragHandleView.heightAnchor.constraint(equalToConstant: style.handleSize.height).isActive = true
//        dragHandleView.centerXAnchor.constraint(equalTo: dragHandleContainerView.centerXAnchor, constant: 0.0).isActive = true
//        dragHandleView.centerYAnchor.constraint(equalTo: dragHandleContainerView.centerYAnchor, constant: 0.0).isActive = true
//    }
//
//    private func setupHeader() {
//        contentHeaderContainerView = UIView(frame: CGRect(x: 0,
//                                                          y: draggableContainerView.frame.maxY,
//                                                          width: draggableContainerView.frame.width,
//                                                          height: 100.0)) // placeholder height
//        contentHeaderContainerView.backgroundColor = style.backgroundColor
//        contentHeaderContainerView.translatesAutoresizingMaskIntoConstraints = false
//        draggableContainerView.addSubview(contentHeaderContainerView)
//        contentHeaderContainerView.leadingAnchor.constraint(equalTo: draggableContainerView.leadingAnchor, constant: 0.0).isActive = true
//        contentHeaderContainerView.trailingAnchor.constraint(equalTo: draggableContainerView.trailingAnchor, constant: 0.0).isActive = true
//        contentHeaderContainerView.topAnchor.constraint(equalTo: dragHandleContainerView.bottomAnchor, constant: 0.0).isActive = true
//    }
//
//    private func setupContent() {
//        contentMainContainerView = UIView(frame: CGRect(x: 0,
//                                                        y: contentHeaderContainerView.frame.maxY,
//                                                        width: draggableContainerView.frame.width,
//                                                        height: 100.0)) // placeholder height
//        contentMainContainerView.backgroundColor = style.backgroundColor
//        contentMainContainerView.translatesAutoresizingMaskIntoConstraints = false
//        draggableContainerView.addSubview(contentMainContainerView)
//        contentMainContainerView.topAnchor.constraint(equalTo: contentHeaderContainerView.bottomAnchor, constant: 0.0).isActive = true
//        contentMainContainerView.leadingAnchor.constraint(equalTo: draggableContainerView.leadingAnchor, constant: 0.0).isActive = true
//        contentMainContainerView.trailingAnchor.constraint(equalTo: draggableContainerView.trailingAnchor, constant: 0.0).isActive = true
//        contentMainContainerView.bottomAnchor.constraint(equalTo: draggableContainerView.bottomAnchor, constant: 0.0).isActive = true
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        addChild(nestedController)
//
//        // add header content
//        let contentHeaderView = nestedController.contentHeaderView()
//        contentHeaderView.translatesAutoresizingMaskIntoConstraints = false
//        contentHeaderContainerView.addSubview(contentHeaderView)
//        contentHeaderView.leadingAnchor.constraint(equalTo: contentHeaderContainerView.leadingAnchor, constant: 0.0).isActive = true
//        contentHeaderView.trailingAnchor.constraint(equalTo: contentHeaderContainerView.trailingAnchor, constant: 0.0).isActive = true
//        contentHeaderView.topAnchor.constraint(equalTo: contentHeaderContainerView.topAnchor, constant: 0.0).isActive = true
//        contentHeaderView.bottomAnchor.constraint(equalTo: contentHeaderContainerView.bottomAnchor, constant: 0.0).isActive = true
//
//        // add main content
//        let contentMainView = nestedController.contentMainView()
//        contentMainView.translatesAutoresizingMaskIntoConstraints = false
//        contentMainContainerView.addSubview(contentMainView)
//        contentMainView.leadingAnchor.constraint(equalTo: contentMainContainerView.leadingAnchor, constant: 0.0).isActive = true
//        contentMainView.trailingAnchor.constraint(equalTo: contentMainContainerView.trailingAnchor, constant: 0.0).isActive = true
//        contentMainView.topAnchor.constraint(equalTo: contentMainContainerView.topAnchor, constant: 0.0).isActive = true
//        contentMainView.bottomAnchor.constraint(equalTo: contentMainContainerView.bottomAnchor, constant: 0.0).isActive = true
//
//        nestedController.didMove(toParent: self)
//
//        if let contentScrollView = nestedController.contentMainScrollView() {
//            currentContentScrollOffset = contentScrollView.contentOffset
//        }
//
//        updateLayout(state: .hidden, animated: false)
//    }
//
//    // MARK: - Events
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        if style.cornerRadius > 0 {
//            let maskLayer = CAShapeLayer()
//            maskLayer.path = UIBezierPath(
//                roundedRect: draggableContainerView.bounds,
//                byRoundingCorners: [.topLeft, .topRight],
//                cornerRadii: CGSize(width: style.cornerRadius, height: style.cornerRadius)).cgPath
//            draggableContainerView.layer.mask = maskLayer
//        }
//    }
//
//    // MARK: - Public
//
//    /**
//     Helper method, that will add this controller to provided `parentViewController` and add overlay over the whole area of `containerView`.
//     */
//
//    internal func addTo(parentViewController: UIViewController, containerView: UIView, belowSubview subview: UIView? = nil) {
//        parentViewController.addToContainerChildViewController(self, targetView: containerView, belowSubview: subview)
//        view.layoutIfNeeded()
//    }
//
//    internal func removeOverlayFromParentViewController() {
//        removeFromContainerChildViewController()
//    }
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
//    private func bottomSafeAreaInset() -> CGFloat {
//        if #available(iOS 11.0, *) {
//            return view.safeAreaInsets.bottom
//        } else {
//            return bottomLayoutGuide.length
//        }
//    }
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

//// MARK: - UIGestureRecognizerDelegate
//
//extension DraggableDetailsOverlayViewController: UIGestureRecognizerDelegate {
//
//    private func isContentScrollAtTop() -> Bool {
//        if let contentScrollview = nestedController.contentMainScrollView() {
//            return contentScrollview.contentOffset.y <= -contentScrollview.contentInset.top
//        }
//        return true
//    }
//
//    @objc private func handleDragGesture(_ recognizer: UIGestureRecognizer) {
//        guard recognizer === dragGestureRecognizer,
//            state != .hidden
//            else {
//                return
//        }
//        let translationY: CGFloat = dragGestureRecognizer.translation(in: dragGestureRecognizer.view).y
//        let velocityY = dragGestureRecognizer.velocity(in: dragGestureRecognizer.view).y
//        dragGestureRecognizer.setTranslation(CGPoint.zero, in: dragGestureRecognizer.view)
//        switch recognizer.state {
//        case .possible:
//            break
//
//        case .began:
//            if dragGestureRecognizer.numberOfTouches > 0, let contentScrollView = nestedController.contentMainScrollView() {
//                let touchLocation = dragGestureRecognizer.location(ofTouch: 0, in: contentScrollView.superview)
//                if contentScrollView.frame.contains(touchLocation) {
//                    isDragInScroll = true
//                    setPreventContentScroll(true)
//                }
//            }
//
//        case .changed:
//            if draggableContainerTopConstraint.constant != topAncorOffset || isContentScrollAtTop() || !isDragInScroll {
//                let newOffset = draggableContainerTopConstraint.constant + translationY
//                let maxOffset = offsetForState(bottomAncorState)
//                let minOffset = topAncorOffset
//                let preventContentScroll: Bool
//                switch newOffset {
//                case ..<minOffset:
//                    draggableContainerTopConstraint.constant = minOffset
//                    preventContentScroll = false
//
//                case minOffset...maxOffset:
//                    draggableContainerTopConstraint.constant = newOffset
//                    preventContentScroll = true
//
//                case maxOffset...:
//                    draggableContainerTopConstraint.constant = maxOffset
//                    preventContentScroll = true
//
//                default:
//                    // this should not be happening
//                    preventContentScroll = false
//                }
//                setPreventContentScroll(preventContentScroll)
//            } else {
//                setPreventContentScroll(false)
//            }
//
//        case .ended,
//             .cancelled,
//             .failed:
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
//
//        @unknown default:
//            break
//        }
//    }
//
//    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        guard state != .hidden else {
//            return false
//        }
//        return true
//    }
//
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
//                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer === dragGestureRecognizer || otherGestureRecognizer === dragGestureRecognizer {
//            return true
//        }
//        return false
//    }
//
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        guard gestureRecognizer === dragGestureRecognizer,
//            state != .hidden,
//            draggableContainerView.frame.contains(touch.location(in: view))
//            else {
//                return false
//        }
//        return true
//    }
//
//}
//
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
