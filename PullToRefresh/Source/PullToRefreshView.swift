//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
// based on: https://github.com/samvermette/SVPullToRefresh and https://github.com/Friend-LGA/LGRefreshView
//

import UIKit

/**
 Constraints of this view or its subviews MUST NOT define width or height of this view - use stretchable/centered layout
 */
public protocol PullToRefreshContentViewProtocol {

    /**
     This function will be called when visual state of the control changes (including change of state and chage of pull length).
     Look into 'PullToRefreshView.State' and change your content accordingly
     - Parameters:
        - currentPullDistance: current pull length(distance). Can be more than 'targetPullDistance'.
        - targetPullDistance: designated 'length' of the pull-to-refresh control. Refresh event will be triggered, if user pulls more than this length and then releases a touch. A constant value.
        - state: current (new) state of the control.
     */
    func updateState(currentPullDistance: CGFloat, targetPullDistance: CGFloat, state: PullToRefreshView.State)

}

/**
 Pull-to-refresh control.
 Create and add it to the UIScrollView or it's subclass.
 Watches "contentOffset" and a few other properties via KVO to work.
 */
public class PullToRefreshView: UIView {

    public enum State {
        /**
         User is doing nothing or pulling not enough to trigger refresh (less than 'length').
         Proposed content: "pull" animation filled to [pull_length / length] rate.
         */
        case idle

        /**
         User ulled more than 'length'.
         Proposed content: you can handle "over-pulling" or leave pull animation in the final state.
         */
        case readyToTrigger

        /**
         Refreshing action is currently in progress.
         Proposed content: infinite animation (or finite if you know your timings).
         */
        case refreshing

        /**
         Refreshing action is over.
         User must hide control in order to be able to trigger it again.
         Proposed content: hidden
         */
        case finishing
    }

    private enum ObservableKeyPath: String {
        case contentInset
        case contentOffset

        static fileprivate func all() -> [ObservableKeyPath] {
            return [
                ObservableKeyPath.contentInset,
                ObservableKeyPath.contentOffset
            ]
        }
    }

    /**
     Duration of internal animations - animations of content insets/offsets. Used for smooth transitions between states.
     Default value is '0.25 s'.
     */
    public var animationDuration: TimeInterval = 0.25
    /**
     This handler will be called, when control will enter 'refreshing' state.
     */
    public var eventHandler: (() -> Void)?
    /**
     For smooth transition between 'refreshing' and 'idle' state it is better to break current touch. Otherwise content offset will be abruptly changed to 0 and than back to user's drag position (because we are changing 'UIScrollView.contentInsets').
     Default value is 'true'.
     */
    public var canCancelTouches: Bool = true
    /**
     If size of content of UIScrollView is equal or greater than size of UIScrollView itself AND current offset is 0, than programmatic triggering of refreshing animation (via 'trigger()' or 'beginRefreshAnimation()') will be invisible for user - content offset will not be changed. If this flag is 'true' than content offset will be animated to reveal animating refresh control to user.
     It is recommended to enable this option, if size of initial/empty content of UIScrollView is big.
     Default value is 'false'.
     */
    public var adjustsOffsetToVisible: Bool = false
    /**
     Setting new value to this property will reset state of the control to 'idle'.
     If control is disabled, public methods will do nothing and control will not respond to changes in scroll view.
     Default value is 'true'.
     */
    public var isEnabled: Bool = true {
        didSet {
            if isEnabled != oldValue {
                resetState(refreshOriginalContentInsets: isEnabled)
            }
        }
    }

    private var observerContext: Int = 0
    private var observablePaths: [ObservableKeyPath] = []
    private let length: CGFloat
    private let contentView: PullToRefreshContentViewProtocol & UIView
    private var topConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var originalContentInset: UIEdgeInsets = UIEdgeInsets.zero
    private var ignoreContentInsetChanges: Bool = false                 // to break recursion
    private var ignoreContentOffsetChanges: Bool = false
    private var state: State = .idle
    private var currentPullLength: CGFloat = 0

    // MARK: - Initialization

    override public init(frame: CGRect) {
        fatalError("PullToRefreshView init(scrollView:position:length:contentView:)")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("PullToRefreshView: init(scrollView:position:length:contentView:)")
    }

    /**
     Designated initializer.
     - Parameters:
        - scrollView: parent scroll view it must be it's subclass - UITableView or UICollectionView
        - length: length of the view. It is width for horizontal pull (`.left` and `.right`) and height for vertical pull (`.top` and `.bottom`)
        - contentView: content view that will display some kind of pull/refreshing animation
     */
    public init(scrollView: UIScrollView,
                length aLength: CGFloat,
                contentView aContentView: PullToRefreshContentViewProtocol & UIView) {
        // privates
        originalContentInset = scrollView.contentInset
        length = aLength
        contentView = aContentView

        // self
        super.init(frame: CGRect(x: 0, y: 0, width: aLength, height: aLength))
        backgroundColor = UIColor.clear

        // form view hierarchy with constraints
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = heightAnchor.constraint(equalToConstant: length)
        heightConstraint?.isActive = true
        scrollView.insertSubview(self, at: 0)

        // content constraints
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.frame = bounds
        contentView.clipsToBounds = true
        addSubview(contentView)
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true
        contentView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0).isActive = true
    }

    // MARK: - Public

    /**
     Trigger pull-to-refresh event and animation.
     */
    public func trigger() {
        guard isEnabled else {
            return
        }
        setState(.refreshing, report: true)
    }

    /**
     Start refreshing animation. this will not trigger the event.
     */
    public func beginRefreshingAnimation() {
        guard isEnabled else {
            return
        }
        setState(.refreshing, report: false)
    }

    /**
     End refreshing animation. You must call this manually after your "refreshing" task is complete.
     Is recommended to call this before you do any updates to table/collection view (like reloadRows()).
     */
    public func endRefreshingAnimation() {
        guard isEnabled else {
            return
        }
        setState(.finishing, report: false)
    }

    // MARK: - Events

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        // remove previous observers
        if let oldParentScrollView = parentScrollView {
            for path in observablePaths {
                oldParentScrollView.removeObserver(self, forKeyPath: path.rawValue, context: &observerContext)
            }
            observablePaths.removeAll()
        }

        // add new observers
        if let newParentScrollView = newSuperview as? UIScrollView {
            for path in ObservableKeyPath.all() {
                newParentScrollView.addObserver(self, forKeyPath: path.rawValue, options: [.new, .old], context: &observerContext)
                observablePaths.append(path)
            }
        }
    }

    public override func didMoveToSuperview() {
        // setup own constraints
        if let realSuperview = parentScrollView {
            widthAnchor.constraint(equalTo: realSuperview.widthAnchor).isActive = true
            centerXAnchor.constraint(equalTo: realSuperview.centerXAnchor).isActive = true
            bottomAnchor.constraint(equalTo: realSuperview.topAnchor).isActive = true
        }
    }

    // MARK: - Private

    // MARK: KVO

    // NOTE: old version of KVO is used, because new version removes observers not immediatly - this causes crash on iOs 10.*
    // swiftlint:disable block_based_kvo
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // swiftlint:enable block_based_kvo
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        if let observedObject = object as? UIScrollView,
            observedObject === self.superview,
            let realKeyPath = keyPath,
            let path = ObservableKeyPath(rawValue: realKeyPath),
            let newValue = change?[NSKeyValueChangeKey.newKey] as? NSValue,
            let oldValue = change?[NSKeyValueChangeKey.oldKey] as? NSValue {
            switch path {
            case .contentInset:
                processContentInsetChange(newValue: newValue.uiEdgeInsetsValue, oldValue: oldValue.uiEdgeInsetsValue)

            case .contentOffset:
                processContentOffsetChange(newValue: newValue.cgPointValue, oldValue: oldValue.cgPointValue, forced: false)
            }
        }
    }

    private func processContentInsetChange(newValue: UIEdgeInsets, oldValue: UIEdgeInsets) {
        guard isEnabled, !ignoreContentInsetChanges, newValue != oldValue else {
            return
        }
        originalContentInset = newValue
    }

    private func processContentOffsetChange(newValue: CGPoint, oldValue: CGPoint, forced: Bool) {
        guard isEnabled, !ignoreContentOffsetChanges, (newValue != oldValue) || forced, let scrollView = parentScrollView else {
            return
        }
        let newOffset = newValue
        let newPullLength = -newOffset.y - originalContentInset.top
        switch state {
        case .idle:
            if newPullLength > length {
                setPullLength(newPullLength, report: false)
                setState(.readyToTrigger, report: true)
            } else {
                setPullLength(newPullLength, report: true)
            }

        case .readyToTrigger:
            if newPullLength < 0 {
                setPullLength(newPullLength, report: false)
                setState(.idle, report: true)
            } else if !scrollView.isTracking {
                setPullLength(newPullLength, report: false)
                setState(.refreshing, report: true)
            } else {
                setPullLength(newPullLength, report: true)
            }

        case .refreshing:
            setPullLength(newPullLength, report: true)
            // we can move out of this state only via endRefreshingAnimation()

        case .finishing:
            if newPullLength <= 0 {
                setPullLength(newPullLength, report: false)
                setState(.idle, report: true)
            } else {
                setPullLength(newPullLength, report: true)
            }
        }
    }

    // MARK: Supplemental

    private var parentScrollView: UIScrollView? {
        return self.superview as? UIScrollView
    }

    private func resetState(refreshOriginalContentInsets: Bool) {
        if refreshOriginalContentInsets, let scrollview = parentScrollView {
            originalContentInset = scrollview.contentInset
        }
        setPullLength(0, report: false)
        setState(.idle, report: true)
    }

    private func setState(_ newValue: State, report: Bool) {
        guard state != newValue, let scrollView = parentScrollView else {
            return
        }
        state = newValue
        contentView.updateState(currentPullDistance: currentPullLength, targetPullDistance: length, state: state)
        switch newValue {
        case .idle,
             .readyToTrigger:
            let newInsets = originalContentInset
            if scrollView.contentInset != newInsets {
                if scrollView.isTracking == true {
                    self.ignoreContentInsetChanges = true
                    self.ignoreContentOffsetChanges = true
                    var newOffset = scrollView.contentOffset
                    newOffset.y -= scrollView.contentInset.top - newInsets.top
                    scrollView.contentInset = newInsets
                    scrollView.contentOffset = newOffset
                    self.ignoreContentInsetChanges = false
                    self.ignoreContentOffsetChanges = false
                } else {
                    UIView.animate(
                        withDuration: animationDuration,
                        delay: 0.0,
                        options: .allowUserInteraction,
                        animations: {
                            self.ignoreContentInsetChanges = true
                            self.ignoreContentOffsetChanges = true
                            scrollView.contentInset = newInsets
                            self.ignoreContentInsetChanges = false
                            self.ignoreContentOffsetChanges = false
                    },
                        completion: nil)
                }
            }

        case .refreshing:
            if report {
                eventHandler?()
            }
            var newInsets = originalContentInset
            newInsets.top += length
            if scrollView.contentInset != newInsets {
                if adjustsOffsetToVisible && !scrollView.isTracking && scrollView.contentOffset.y == 0 {
                    var newOffset = scrollView.contentOffset
                    newOffset.y -= length
                    UIView.animate(
                        withDuration: animationDuration,
                        delay: 0.0,
                        options: [.allowUserInteraction, .beginFromCurrentState],
                        animations: {
                            self.ignoreContentInsetChanges = true
                            self.ignoreContentOffsetChanges = true
                            scrollView.contentInset = newInsets
                            scrollView.contentOffset = newOffset
                            self.ignoreContentInsetChanges = false
                            self.ignoreContentOffsetChanges = false
                            self.setPullLength(self.length, report: true)
                    },
                        completion: nil)
                } else {
                    UIView.animate(
                        withDuration: animationDuration,
                        delay: 0.0,
                        options: [.allowUserInteraction, .beginFromCurrentState],
                        animations: {
                            self.ignoreContentInsetChanges = true
                            self.ignoreContentOffsetChanges = true
                            scrollView.contentInset = newInsets
                            self.ignoreContentInsetChanges = false
                            self.ignoreContentOffsetChanges = false
                            self.setPullLength(self.length, report: true)
                    },
                        completion: nil)
                }
            }

        case .finishing:
            let newInsets = originalContentInset
            let oldOffset = scrollView.contentOffset
            if scrollView.contentInset != newInsets {
                UIView.animate(
                    withDuration: animationDuration,
                    delay: 0.0,
                    options: [.allowUserInteraction, .beginFromCurrentState],
                    animations: {
                        self.ignoreContentInsetChanges = true
                        self.ignoreContentOffsetChanges = true
                        scrollView.contentInset = newInsets
                        self.ignoreContentInsetChanges = false
                        self.ignoreContentOffsetChanges = false
                },
                    completion: { (finished: Bool) in
                        if finished {
                            self.processContentOffsetChange(newValue: scrollView.contentOffset, oldValue: oldOffset, forced: true)
                        }
                })
            } else {
                self.processContentOffsetChange(newValue: scrollView.contentOffset, oldValue: oldOffset, forced: true)
            }
            if canCancelTouches && scrollView.isTracking {
                scrollView.panGestureRecognizer.isEnabled = false
                scrollView.panGestureRecognizer.isEnabled = true
            }
        }
    }

    private func setPullLength(_ newValue: CGFloat, report: Bool) {
        heightConstraint?.constant = CGFloat.maximum(newValue, 0)
        superview?.layoutIfNeeded()
        currentPullLength = newValue
        if report {
            contentView.updateState(currentPullDistance: newValue, targetPullDistance: length, state: state)
        }
    }

}
