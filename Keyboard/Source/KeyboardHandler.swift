//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

/**
 Utility to handle keyboard appearing & disapearing "in one line".
 */
public class KeyboardHandler {

    private enum Constant {
        static let defaultAnimationDuration: TimeInterval = 0.25
    }

    /**
     if `false` notifications about keyboard changes will be skipped.
     Default value is `false`.
     */
    public var isActive: Bool = false

    private var heightDidChange: (CGFloat, TimeInterval) -> Void
    private var observerTokens: [NSObjectProtocol]

    // MARK: - Initialization

    /**
     - parameter aHeightDidChange - block, will be called on main thread
     */
    public init(heightDidChange aHeightDidChange: @escaping (_ newHeightValue: CGFloat, _ animationDuration: TimeInterval) -> Void) {
        heightDidChange = aHeightDidChange
        observerTokens = []

        let center: NotificationCenter = NotificationCenter.default
        let willShowKeyboardObserverToken = center.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: nil, using: { (notification) in
            self.processKeyboardNotification(notification)
        })
        observerTokens.append(willShowKeyboardObserverToken)

        let willHideKeyboardObserverToken = center.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: nil, using: { (notification) in
            self.processKeyboardNotification(notification)
        })
        observerTokens.append(willHideKeyboardObserverToken)
    }

    deinit {
        let center: NotificationCenter = NotificationCenter.default
        for token in observerTokens {
            center.removeObserver(token)
        }
    }

    // MARK: - Private

    private func processKeyboardNotification(_ notification: Notification) {
        if isActive,
            let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.floatValue,
            let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let timeInterval = (duration > 0) ? TimeInterval(duration) : Constant.defaultAnimationDuration
            let screenSize: CGRect = UIScreen.main.bounds
            let height = screenSize.height - keyboardFrame.origin.y
            DispatchQueue.main.async(execute: {
                self.heightDidChange(height, timeInterval)
            })
        }
    }
}
