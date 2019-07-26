//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import UIKit

/**
 Delegate of the draggable overlay. The one whole controls it.
 */
public protocol DraggableDetailsOverlayViewControllerDelegate: class {

    /**
     An array of anchors, that overlay will use for snapping. Anchors pointing to effectively the same point will be reduced to singular anchor.
     */
    func draggableDetailsOverlayAnchors(_ overlay: DraggableDetailsOverlayViewController) -> [DraggableDetailsOverlayViewController.Anchor]

    /**
     Amount of background from the top, that overlay is not allowed to cover.
     Return 0 to be able to cover every available space.
     */
    func draggableDetailsOverlayTopInset(_ overlay: DraggableDetailsOverlayViewController) -> CGFloat

    /**
     Maximum height of overlay.
     Return `nil` if height should not be limited.
     */
    func draggableDetailsOverlayMaxHeight(_ overlay: DraggableDetailsOverlayViewController) -> CGFloat?

    /**
     This will also be reported, when user draggs overlay beyond allowed anchors (and overlay do not actually moves).
     */
    func draggableDetailsOverlayDidDrag(_ overlay: DraggableDetailsOverlayViewController)

    /**
     Content's scroll will still be prevented for another runloop.
     */
    func draggableDetailsOverlayDidEndDragging(_ overlay: DraggableDetailsOverlayViewController)

    /**
     Called on automatic and manual invoke of `show()` & `hide()`.
     */
    func draggableDetailsOverlayDidChangeIsVisible(_ overlay: DraggableDetailsOverlayViewController)

    func draggableDetailsOverlayDidUpdatedLayout(_ overlay: DraggableDetailsOverlayViewController)

}

/**
 Interface for controller, that will be displayed inside draggable overlay.
 Content's layout notes:
    - height of container for content is dynamic and will change with drag.
    - minimum height is 0
    - priority of container's bottom constraint is 999
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

/**
 Overlay that can be dragged to cover more or less of available space.
 Can be configured to be "twitter-like". With limited content height.
 */
public class DraggableDetailsOverlayViewController: UIViewController {

    public typealias NestedConstroller = UIViewController & DraggableDetailsOverlayNestedInterface

    public enum Anchor {
        case top(offset: CGFloat)
        case middle(height: CGFloat)
    }

    private enum Constant {
        static let hiddenContainerOffset: CGFloat = 10
        /**
         Anchors will be considered equal if they separated by no more than this amount of points.
         */
        static let anchorsCachingGranularity: CGFloat = 1.0
    }

    /**
     Is on/off screen?
     Changes at the start of show() and at the end of hide().
     */
    public private(set) var isVisible: Bool = false {
        didSet {
            delegate?.draggableDetailsOverlayDidChangeIsVisible(self)
        }
    }

    /**
     Enable shadow background.
     Shadow will block interaction with everything underneath.
     Default value is `true`.
     */
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

    public var draggableContainerTopCornersRadius: CGFloat = 5 { //TODO: 58: example
        didSet {
            guard isViewLoaded else { return }
            draggableContainerView.layer.cornerRadius = draggableContainerTopCornersRadius
            draggableContainerBottomConstraint.constant = draggableContainerTopCornersRadius
            contentContainerBottomConstraint.constant = -draggableContainerTopCornersRadius
        }
    }

    /**
     Container for drag-handle.
     Handle is centered here.
     Use 0 to hide handle.
     Default value is `16`.
     */
    public var handleContainerHeight: CGFloat = 16 { //TODO: 58: example
        didSet {
            guard isViewLoaded else { return }
            handleHeightConstraint.constant = handleContainerHeight
        }
    }

    public var handleColor: UIColor = UIColor.lightGray { //TODO: 58: example
        didSet {
            guard isViewLoaded else { return }
            handleView.handleView.backgroundColor = handleColor
        }
    }

    /**
     Size of drag-handle element.
     Default value is `36 x 4`.
     */
    public var handleSize: CGSize = CGSize(width: 36, height: 4) { //TODO: 58: example
        didSet {
            guard isViewLoaded else { return }
            handleView.handleWidthConstraint.constant = handleSize.width
            handleView.handleHeightConstraint.constant = handleSize.height
        }
    }

    /**
     Corner radius value for drag-handle element.
     Independent of it's height.
     Default value is `2`.
     */
    public var handleCornerRadius: CGFloat = 2 { //TODO: 58: example
        didSet {
            guard isViewLoaded else { return }
            handleView.handleView.layer.cornerRadius = handleCornerRadius
        }
    }

    /**
     Animation duration for `show()` & `hide()` & `updateLayout(animated:)`.
     Default value is `0.25`.
     */
    public var showHideAnimationDuration: TimeInterval = 0.25 //TODO: 58: example

    /**
     If enabled - overlay will be snap-animated to nearest anchor.
     Affects drag and show().
     Default value `true`.
     */
    public var isSnapToAnchorsEnabled: Bool = true //TODO: 58: example

    /**
     If enabled, user can drag overlay below bottom
     Default value `false`.
     */
    public var isDragOffScreenToHideEnabled: Bool = false //TODO: 58: example

    /**
     If enabled - user can over-drag overlay beyond most periferal anchors.
     Over-drag is affected by `bounceDragDumpening`.
     Default value is `false`.
     */
    public var isBounceEnabled: Bool = false //TODO: 58: example

    /**
     How much harder it is to over-drag (comparing to normal drag).
     Default value is `0.5`.
     */
    public var bounceDragDumpening: CGFloat = 0.5 //TODO: 58: example

    /**
     If `false` - snapping anchor will be calculated from current position of overlay.
     If `true` - current position + touch velocity will be used.
     Default value is `true`.
     */
    public var snapCalculationUsesDeceleration: Bool = true //TODO: 58: example

    /**
     If `false` - When user releases touch with some velocity,
     decelerating behaviour can't snap to anchors other then current or immediate next/previous one.
     Default value is `true`.
     */
    public var snapCalculationDecelerationCanSkipNextAnchor: Bool = true //TODO: 58: example

    /**
     Deceleartion rate used for calculation of snap anchors.
     Default value is `UIScrollView.DecelerationRate.normal`
     */
    public var snapCalculationDecelerationRate: UIScrollView.DecelerationRate = .normal //TODO: 58: example

    /**
     Duration of animation used, when user releases finger during drag.
     Default value is `0.2`.
     */
    public var snapAnimationNormalDuration: TimeInterval = 0.2 //TODO: 58: example

    /**
     Use spring animation for snapping to anchors.
     Spring is not used in `show()`.
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
     Default value is `0.4`.
     */
    public var snapAnimationSpringDuration: TimeInterval = 0.4 //TODO: 58: example

    /**
     Parameter of spring animation (if enabled).
     Default value is `0.7`.
     */
    public var snapAnimationSpringDamping: CGFloat = 0.7 //TODO: 58: example

    /**
     Parameter of spring animation (if enabled).
     Default value is `1.5`.
     */
    public var snapAnimationSpringInitialVelocity: CGFloat = 1.5 //TODO: 58: example

    private var shadowBackgroundView: UIView!
    private var draggableContainerView: UIView!
    private var draggableContainerHiddenTopConstraint: NSLayoutConstraint!
    private var draggableContainerShownTopConstraint: NSLayoutConstraint!
    private var draggableContainerBottomConstraint: NSLayoutConstraint!
    private var contentContainerView: UIView!
    private var contentContainerBottomConstraint: NSLayoutConstraint!
    private var handleView: DraggableDetailsOverlayHandleView!
    private var handleHeightConstraint: NSLayoutConstraint!
    private var dragGestureRecognizer: UIPanGestureRecognizer!

    private let nestedController: NestedConstroller
    private weak var delegate: DraggableDetailsOverlayViewControllerDelegate?

    private var anchors: [Anchor] = []
    /**
     Sorted top->bottom (lowest->highest).
     */
    private var cachedAnchorOffsets: [CGFloat] = [0]
    private var screenBottomOffset: CGFloat = 0
    /**
     Height for which offsets/heights were cached/calculated.
     */
    private var layoutCalculatedForHeight: CGFloat = 0

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

        updateAnchors()

        setupShadowBackgroundView()
        setupDraggableContainer()
        setupHandle()
        setupContentContainer()
        setupPanRecognizer()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(nestedController, notifyAboutAppearanceTransition: false, targetContainerView: contentContainerView)
    }

    // MARK: - Events

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout(animated: false, forced: false)
    }

    // MARK: - Public

    /**
     Affected by `isSnapToAnchorsEnabled`
     */
    public func show(initialAnchor: Anchor, animated: Bool) {
        setVisible(true, animated: animated, initialAnchor: initialAnchor)
    }

    public func hide(animated: Bool) {
        setVisible(false, animated: animated, initialAnchor: .top(offset: 0))
    }

    public func updateLayout(animated: Bool) {
        updateLayout(animated: animated, forced: true)
    }

    /**
     Current vertical space between allowed area's top and draggable container's top.
     Return's nil if view is not loaded or if overlay is hidden.
     */
    public func currentTopOffset() -> CGFloat? {
        guard isViewLoaded, isVisible else {
            return nil
        }
        return draggableContainerShownTopConstraint.constant
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
                let touchLocation = dragGestureRecognizer.location(in: scroll.superview)
                return scroll.frame.contains(touchLocation)
            })
            setPreventContentScroll(true)

        case .changed:
            if isContentScrollAtTop(contentScrollView: currentPanStartingContentScrollView) || translationY < 0 {
                let newOffset = draggableContainerShownTopConstraint.constant + translationY
                let maxOffset = cachedAnchorOffsets.last ?? 0
                let minOffset = cachedAnchorOffsets.first ?? 0
                let newShadowAlpha: CGFloat
                if newOffset < minOffset {
                    if isBounceEnabled {
                        let dumpenedNewOffset = draggableContainerShownTopConstraint.constant + translationY * bounceDragDumpening
                        draggableContainerShownTopConstraint.constant = dumpenedNewOffset
                        newShadowAlpha = 1.0
                        setPreventContentScroll(true)
                    } else {
                        draggableContainerShownTopConstraint.constant = minOffset
                        newShadowAlpha = 1.0
                        setPreventContentScroll(false)
                    }
                } else if minOffset <= newOffset && newOffset <= maxOffset {
                    draggableContainerShownTopConstraint.constant = newOffset
                    newShadowAlpha = 1.0
                    setPreventContentScroll(true)
                } else { // newOffset > maxOffset
                    if isDragOffScreenToHideEnabled {
                        draggableContainerShownTopConstraint.constant = newOffset
                        newShadowAlpha = CGFloat.maximum((screenBottomOffset - newOffset) / (screenBottomOffset - maxOffset), 0.0)
                        setPreventContentScroll(true)
                    } else if isBounceEnabled {
                        let dumpenedNewOffset = draggableContainerShownTopConstraint.constant + translationY * bounceDragDumpening
                        draggableContainerShownTopConstraint.constant = dumpenedNewOffset
                        newShadowAlpha = 1.0
                        setPreventContentScroll(true)
                    } else {
                        draggableContainerShownTopConstraint.constant = maxOffset
                        newShadowAlpha = 1.0
                        setPreventContentScroll(false)
                    }
                }
                if isShadowEnabled {
                    shadowBackgroundView.alpha = newShadowAlpha
                }
                delegate?.draggableDetailsOverlayDidDrag(self)
            } else {
                setPreventContentScroll(false)
            }

        case .ended,
             .cancelled,
             .failed:
            if isContentScrollAtTop(contentScrollView: currentPanStartingContentScrollView) || translationY < 0 {
                let currentOffset = draggableContainerShownTopConstraint.constant
                if isSnapToAnchorsEnabled {
                    let restOffset: CGFloat
                    let shouldHide: Bool
                    if snapCalculationUsesDeceleration {
                        let deceleratedOffset = DecelerationHelper.project(
                            value: currentOffset,
                            initialVelocity: velocity.y / 1000.0, /* because this should be in milliseconds */
                            decelerationRate: snapCalculationDecelerationRate.rawValue)
                        if snapCalculationDecelerationCanSkipNextAnchor {
                            let closestAnchor = closestAnchorOffset(targetOffset: deceleratedOffset)
                            restOffset = closestAnchor.anchorOffset
                            shouldHide = closestAnchor.shouldHide
                        } else {
                            let closestAnchor = closestAnchorOffset(targetOffset: deceleratedOffset, currentOffset: currentOffset)
                            restOffset = closestAnchor.anchorOffset
                            shouldHide = closestAnchor.shouldHide
                        }
                    } else {
                        let closestAnchor = closestAnchorOffset(targetOffset: currentOffset)
                        restOffset = closestAnchor.anchorOffset
                        shouldHide = closestAnchor.shouldHide
                    }
                    if isDragOffScreenToHideEnabled && shouldHide {
                        hide(animated: currentOffset < screenBottomOffset)
                    } else if currentOffset != restOffset {
                        let isSpring = restOffset == cachedAnchorOffsets.first ? snapAnimationTopAnchorUseSpring : snapAnimationUseSpring
                        animateToOffset(restOffset, isSpring: isSpring)
                    }
                } else if isDragOffScreenToHideEnabled && currentOffset >= screenBottomOffset {
                    hide(animated: false)
                }
                currentPanStartingContentScrollView = nil
                DispatchQueue.main.async(execute: { // to prevent deceleration behaviour in content's scroll
                    self.setPreventContentScroll(false)
                })
            }
            delegate?.draggableDetailsOverlayDidEndDragging(self)

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

    private func setupShadowBackgroundView() {
        shadowBackgroundView = UIView(frame: view.bounds)
        shadowBackgroundView.backgroundColor = shadowBackgroundColor
        shadowBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shadowBackgroundView)
        shadowBackgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        shadowBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        shadowBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        shadowBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        shadowBackgroundView.isHidden = !isShadowEnabled
        shadowBackgroundView.alpha = 0.0
    }

    private func setupDraggableContainer() {
        draggableContainerView = UIView(frame: view.bounds)
        draggableContainerView.backgroundColor = draggableContainerBackgroundColor
        draggableContainerView.layer.masksToBounds = true
        draggableContainerView.layer.cornerRadius = draggableContainerTopCornersRadius
        draggableContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(draggableContainerView)
        if #available(iOS 11.0, *) {
            draggableContainerShownTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            draggableContainerHiddenTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: view.bottomAnchor,
                                                                                                constant: Constant.hiddenContainerOffset)
        } else {
            draggableContainerShownTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor)
            draggableContainerHiddenTopConstraint = draggableContainerView.topAnchor.constraint(equalTo: view.bottomAnchor,
                                                                                                constant: Constant.hiddenContainerOffset)
        }
        draggableContainerShownTopConstraint.isActive = false
        draggableContainerHiddenTopConstraint.isActive = true
        draggableContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        draggableContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        draggableContainerBottomConstraint = draggableContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                                                            constant: draggableContainerTopCornersRadius)
        draggableContainerBottomConstraint.priority = UILayoutPriority(rawValue: 999)
        draggableContainerBottomConstraint.isActive = true
    }

    private func setupHandle() {
        handleView = DraggableDetailsOverlayHandleView(
            frame: CGRect(x: 0, y: 0, width: draggableContainerView.bounds.width, height: handleContainerHeight),
            handleColor: handleColor,
            handleSize: handleSize,
            handleCornerRadius: handleCornerRadius)
        handleView.translatesAutoresizingMaskIntoConstraints = false
        draggableContainerView.addSubview(handleView)
        handleView.leadingAnchor.constraint(equalTo: draggableContainerView.leadingAnchor).isActive = true
        handleView.trailingAnchor.constraint(equalTo: draggableContainerView.trailingAnchor).isActive = true
        handleView.topAnchor.constraint(equalTo: draggableContainerView.topAnchor).isActive = true
        handleHeightConstraint = handleView.heightAnchor.constraint(equalToConstant: handleContainerHeight)
        handleHeightConstraint.isActive = true
    }

    private func setupContentContainer() {
        contentContainerView = UIView(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: draggableContainerView.bounds.width,
                                                    height: draggableContainerView.bounds.height - handleContainerHeight))
        contentContainerView.backgroundColor = UIColor.clear
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        draggableContainerView.addSubview(contentContainerView)
        contentContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        contentContainerView.leadingAnchor.constraint(equalTo: draggableContainerView.leadingAnchor).isActive = true
        contentContainerView.trailingAnchor.constraint(equalTo: draggableContainerView.trailingAnchor).isActive = true
        contentContainerView.topAnchor.constraint(equalTo: handleView.bottomAnchor).isActive = true
        contentContainerBottomConstraint = contentContainerView.bottomAnchor.constraint(equalTo: draggableContainerView.bottomAnchor,
                                                                                        constant: -draggableContainerTopCornersRadius)
        contentContainerBottomConstraint.isActive = true
    }

    private func setupPanRecognizer() {
        dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragGesture))
        dragGestureRecognizer.delegate = self
        dragGestureRecognizer.isEnabled = true
        view.addGestureRecognizer(dragGestureRecognizer)
    }

    private func updateAnchors() {
        anchors = delegate?.draggableDetailsOverlayAnchors(self) ?? [.top(offset: 0)]
        let topInset = calculateTopInset()
        var newOffsets: [CGFloat] = []
        screenBottomOffset = view.bounds.height
        for anchor in anchors {
            let offset = offsetForAnchor(anchor, topInset: topInset)
            // ignore very small steps
            if !newOffsets.contains(where: { isOffsetsEqual($0, offset) }) && !isOffsetsEqual(screenBottomOffset, offset) {
                newOffsets.append(offset)
            }
        }
        cachedAnchorOffsets = newOffsets.sorted(by: { $0 < $1 })
    }

    private func offsetForAnchor(_ anchor: Anchor, topInset: CGFloat) -> CGFloat {
        switch anchor {
        case .top(let uncoverableOffset):
            return min(view.bounds.height, max(uncoverableOffset, topInset))
        case .middle(let containerHeight):
            return min(view.bounds.height, max(topInset, view.bounds.height - containerHeight - bottomSafeAreaInset()))
        }
    }

    /**
     Calculates closest anchor regardless of current position.
     */
    private func closestAnchorOffset(targetOffset: CGFloat) -> (anchorOffset: CGFloat, shouldHide: Bool) {
        let closestAnchor = cachedAnchorOffsets.min(by: { return abs($0 - targetOffset) < abs($1 - targetOffset)}) ?? 0
        let shouldHide = abs(closestAnchor - targetOffset) > abs(screenBottomOffset - targetOffset)
        return (closestAnchor, shouldHide)
    }

    /**
     Calculates closes anchor from current position (current or next or previous).
     */
    private func closestAnchorOffset(targetOffset: CGFloat, currentOffset: CGFloat) -> (anchorOffset: CGFloat, shouldHide: Bool) {
        let currentAnchor = cachedAnchorOffsets.first(where: { abs($0 - currentOffset) < Constant.anchorsCachingGranularity })
        let nextAnchor: CGFloat?
        let previousAnchor: CGFloat?
        if let realCurrentAnchor = currentAnchor {
            nextAnchor = cachedAnchorOffsets.first(where: { $0 > realCurrentAnchor })
            previousAnchor = cachedAnchorOffsets.last(where: { $0 < realCurrentAnchor })
        } else {
            nextAnchor = cachedAnchorOffsets.first(where: { $0 > currentOffset })
            previousAnchor = cachedAnchorOffsets.last(where: { $0 < currentOffset })
        }
        let anchors = [previousAnchor, currentAnchor, nextAnchor].compactMap({ $0 })
        let closestAnchor = anchors.min(by: { return abs($0 - targetOffset) < abs($1 - targetOffset)}) ?? 0
        let shouldHide = abs(closestAnchor - targetOffset) > abs(screenBottomOffset - targetOffset)
        return (closestAnchor, shouldHide)
    }

    private func bottomSafeAreaInset() -> CGFloat {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets.bottom
        } else {
            return bottomLayoutGuide.length
        }
    }

    private func calculateTopInset() -> CGFloat {
        let topInsetFromMaxHeight: CGFloat
        if let maxHeight = delegate?.draggableDetailsOverlayMaxHeight(self) {
            topInsetFromMaxHeight = max(0, view.bounds.height - maxHeight)
        } else {
            topInsetFromMaxHeight = 0
        }
        return max(topInsetFromMaxHeight, delegate?.draggableDetailsOverlayTopInset(self) ?? 0)
    }

    private func isOffsetsEqual(_ left: CGFloat, _ right: CGFloat) -> Bool {
        return abs(left - right) < Constant.anchorsCachingGranularity
    }

    private func updateLayout(animated: Bool, forced: Bool) {
        guard view.bounds.height != layoutCalculatedForHeight || forced else {
            return
        }
        updateAnchors()
        if isVisible {
            let newCurrentOffset = closestAnchorOffset(targetOffset: draggableContainerShownTopConstraint.constant)
            if newCurrentOffset.anchorOffset != draggableContainerShownTopConstraint.constant {
                if animated {
                    animateToOffset(newCurrentOffset.anchorOffset, isSpring: false)
                } else {
                    draggableContainerShownTopConstraint.constant = newCurrentOffset.anchorOffset
                }
            }
        }
        layoutCalculatedForHeight = view.bounds.height
        delegate?.draggableDetailsOverlayDidUpdatedLayout(self)
    }

    private func setVisible(_ newVisible: Bool, animated: Bool, initialAnchor: Anchor) {
        let initialOffset: CGFloat
        if newVisible {
            isVisible = true
            updateLayout(animated: false, forced: true)
            view.isHidden = false
            let topInset = calculateTopInset()
            let wantedOffset = offsetForAnchor(initialAnchor, topInset: topInset)
            initialOffset = isSnapToAnchorsEnabled ? closestAnchorOffset(targetOffset: wantedOffset).anchorOffset : wantedOffset
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
                self.isVisible = false
            }
        }
        if animated {
            UIView.animate(
                withDuration: showHideAnimationDuration,
                delay: 0.0,
                options: [.beginFromCurrentState, .curveEaseOut],
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
            if self.isShadowEnabled {
                self.shadowBackgroundView.alpha = 1.0
            }
            self.draggableContainerShownTopConstraint.constant = targetOffset
            self.view.layoutIfNeeded()
        }
        if isSpring {
            UIView.animate(withDuration: snapAnimationSpringDuration,
                           delay: 0.0,
                           usingSpringWithDamping: snapAnimationSpringDamping,
                           initialSpringVelocity: snapAnimationSpringInitialVelocity,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: animations,
                           completion: nil)
        }
        UIView.animate(withDuration: snapAnimationNormalDuration,
                       delay: 0.0,
                       options: [.beginFromCurrentState, .curveEaseOut],
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
