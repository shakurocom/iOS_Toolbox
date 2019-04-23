//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

internal struct Example {

    internal let title: String
    private let viewControllerType: (UIViewController & ExampleViewControllerProtocol).Type

    internal init(title aTitle: String, viewControllerType aViewControllerType: (UIViewController & ExampleViewControllerProtocol).Type) {
        title = aTitle
        viewControllerType = aViewControllerType
    }

    internal func instantiateViewController() -> UIViewController {
        return viewControllerType.instantiate(example: self)
    }

}

internal extension Example {

    static func all() -> [Example] {
        return [
            Example(title: "DeviceType", viewControllerType: ExampleDeviceTypeViewController.self),
            Example(title: "DeviceOrientationListener", viewControllerType: ExampleDeviceOrientationListenerViewController.self),
            Example(title: "UIStoryboardExtensions", viewControllerType: ExampleUIStoryboardExtensionsViewController.self),
            Example(title: "ImageProcessor", viewControllerType: ExampleImageProcessorViewController.self),
            Example(title: "KeyboardHandler", viewControllerType: ExampleKeyboardHandlerViewController.self),
            Example(title: "KeychainWrapper", viewControllerType: ExampleKeychainWrapperViewController.self),
            Example(title: "PlaceholderTextView", viewControllerType: ExamplePlaceholderTextViewViewController.self),
            Example(title: "VideoCamera", viewControllerType: ExampleVideoCameraViewController.self),
            Example(title: "PullToRefresh", viewControllerType: ExamplePullToRefreshViewController.self),
            Example(title: "PullToRefresh - ShakuroLogo", viewControllerType: ExamplePullToRefreshShakuroLogoViewController.self),
            Example(title: "HTTPClient", viewControllerType: ExampleHTTPClientViewController.self),
            Example(title: "TaskManager", viewControllerType: ExampleTaskManagerViewController.self),
            Example(title: "Labels", viewControllerType: ExampleLabelsViewController.self),
            Example(title: "EMailValidator", viewControllerType: ExampleEMailValidatorViewController.self),
            Example(title: "Settings", viewControllerType: ExampleSettingsViewController.self)
        ]
    }

}
