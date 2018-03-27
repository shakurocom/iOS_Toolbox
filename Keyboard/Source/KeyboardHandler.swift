//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit
//TODO: update documentation
/**
 Utility to handle keyboard appearing & disapearing "in one line".
 */
public class KeyboardHandler {

    /**
     if `false` notifications about keyboard changes will be skipped.
     Default value is `false`.
     */
    public var isActive: Bool = false
    /**
     if `true` changes of keyboard will be handled even if application is in background (resigned active)
     Default value is `false`.
     */
    public var allowChangesInBackground: Bool = false

    private var isAppInBackground: Bool = false
    private var heightDidChange: (CGFloat, TimeInterval) -> Void
    private var observerTokens: [NSObjectProtocol]

    // MARK: - Initialization

    /**
     - Parameters:
        - aHeightDidChange: block, will be called on main thread
        - newHeightValue: new height of the keyboard frame assuming keyboard is sticking to the bottom of the screen
        - animationDuration: duration of the "keyboard hide/show" animation
     */
    public init(heightDidChange aHeightDidChange: @escaping (_ newHeightValue: CGFloat, _ animationDuration: TimeInterval) -> Void) {
        heightDidChange = aHeightDidChange
        observerTokens = []

        let center: NotificationCenter = NotificationCenter.default
        let willEnterForegroundToken = center.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: nil, using: { (notification) in
            self.isAppInBackground = false
        })
        observerTokens.append(willEnterForegroundToken)
        let willResignActiveToken = center.addObserver(forName: NSNotification.Name.UIApplicationWillResignActive, object: nil, queue: nil, using: { (notification) in
            self.isAppInBackground = true
        })
        observerTokens.append(willResignActiveToken)
        let wiilChangeFrameToken = center.addObserver(forName: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil, queue: nil, using: { (notification) in
            self.processKeyboardNotification(notification)
        })
        observerTokens.append(wiilChangeFrameToken)
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
            (!isAppInBackground || allowChangesInBackground),
            let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let screenSize: CGRect = UIScreen.main.bounds
            let height = screenSize.height - keyboardFrame.origin.y
            DispatchQueue.main.async(execute: {
                self.heightDidChange(height, TimeInterval(duration))
            })
        }
    }
}
