//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//

import UIKit
import UserNotifications
import SafariServices

enum CustomTransitionStyle {
    case push
    case pop
    case crossDissolve
}

enum NavigationStyle {
    case push(asRoot: Bool)
    case modal(transitionStyle: UIModalTransitionStyle?, completion: (() -> Void)?)
    case custom(transitionStyle: CustomTransitionStyle)
    case splitDetail

    static let pushDefault: NavigationStyle = .push(asRoot: false)
    static let modalDefault: NavigationStyle = .modal(transitionStyle: nil, completion:nil)
    static let modalCrossDissolve: NavigationStyle = .modal(transitionStyle: .crossDissolve, completion:nil)
}

protocol RouterProtocol: class {

    var isModalViewControllerOnScreen: Bool {get}

    @discardableResult
    func presentURL(_ sender: UIViewController, options: SafariViewControllerOptions) -> SFSafariViewController?

    @discardableResult
    func presentViewController(controller: UIViewController,
                               from: UIViewController?,
                               style: NavigationStyle,
                               animated: Bool) -> UIViewController?

    func popToViewController(_ controller: UIViewController, sender: UIViewController, animated: Bool)
    func popToFirstViewController<ControllerType>(_ controllerType: ControllerType.Type,
                                                  sender: UIViewController,
                                                  animated: Bool)

    func dismissViewController(_ controller: UIViewController, animated: Bool)

    func presentActionSheet(_ title: String?,
                            message: String?,
                            actions: [UIAlertAction],
                            sender: UIViewController?,
                            popoverSourceView: UIView?,
                            animated: Bool)

    func presentAlert(_ title: String?, message: String?, actions: [UIAlertAction], sender: UIViewController?, animated: Bool)
    func presentAlert(_ title: String?, message: String?, sender: UIViewController?, animated: Bool)

    func presentError(_ error: GenericAppError, sender: UIViewController?, animated: Bool)
    func presentError(_ error: GenericAppError,
                      actions: [UIAlertAction],
                      sender: UIViewController?, animated: Bool)
    func presentError(_ errorMessage: String,
                      sender: UIViewController?,
                      animated: Bool)
    func presentError(_ errorMessage: String,
                      actions: [UIAlertAction],
                      sender: UIViewController?,
                      animated: Bool)
}

class Router: RouterProtocol {

    let rootNavigationController: UINavigationController
    private(set) var rootViewController: UIViewController?

    var isModalViewControllerOnScreen: Bool {
        return rootNavigationController.presentedViewController != nil
    }

    init(rootController: UINavigationController) {
        rootNavigationController = rootController
    }

    // MARK: - General

    @discardableResult
    func presentURL(_ sender: UIViewController, options: SafariViewControllerOptions) -> SFSafariViewController? {
        if options.canOpentViaSafariViewController() {
            return SFSafariViewController.present(sender,
                                                  router: self,
                                                  options: options)
        } else {
            debugPrint("can't present SafariViewController for URI: \(options.URI)")
            UIApplication.shared.open(options.URI, options: [:], completionHandler: nil)
            return nil
        }
    }

    @discardableResult
    func presentViewController(controller: UIViewController,
                               from: UIViewController?,
                               style: NavigationStyle,
                               animated: Bool) -> UIViewController? {
        //some of controllers for example MFMessageComposeViewController, can return nil in non optional value even if canSendText() == true
        let uikitBugFixController: UIViewController? = controller
        guard uikitBugFixController != nil else {
            return nil
        }
        switch style {
        case .push(let asRoot):
            let presentingController: UINavigationController = from?.navigationController ?? rootNavigationController
            if asRoot {
                if presentingController === rootNavigationController {
                    rootViewController = controller
                }
                presentingController.setViewControllers([controller], animated: animated)
            } else {
                presentingController.pushViewController(controller, animated: animated)
            }
        case .modal(let transitionStyle, let completion):
            let presentingController: UIViewController = from ?? rootNavigationController
            if let trStyle = transitionStyle {
                controller.modalTransitionStyle = trStyle
            }
            presentingController.present(controller, animated: animated, completion: completion)
        case .custom(let transitionStyle):
            if let customContainer: ContainerViewControllerPresenting = from?.lookupCustomContainerViewControllerPresening() {
                customContainer.present(controller, style: transitionStyle, animated: animated)
            } else {
                assertionFailure("\(type(of: self)) - \(#function): CustomContainerViewControllerPresening is nil")
            }
        case .splitDetail:
            let presentingController: UIViewController = from ?? rootNavigationController
            if let splitViewController = presentingController.splitViewController ?? (presentingController as? UISplitViewController) {
                splitViewController.showDetailViewController(controller, sender: presentingController)
                if animated {
                    controller.view.superview?.layer.addTransitionAnimation(duration: 0.2)
                }
            } else {
                assertionFailure("\(type(of: self)) - \(#function): splitViewController is nil")
            }
        }
        return controller
    }

    func popToFirstViewController<ControllerType>(_ controllerType: ControllerType.Type,
                                                  sender: UIViewController,
                                                  animated: Bool = true) {
        if let navController: UINavigationController = sender.navigationController,
            navController.viewControllers.count > 1 {
            let controllers: [UIViewController] = navController.viewControllers
            for actualController: UIViewController in controllers where (actualController as? ControllerType) != nil {
                navController.popToViewController(actualController, animated: animated)
                break
            }
        }
    }

    func popToViewController(_ controller: UIViewController, sender: UIViewController, animated: Bool = true) {
        if let navController: UINavigationController = sender.navigationController, navController.viewControllers.count > 1 {
            navController.popToViewController(controller, animated: animated)
        }
    }

    func dismissViewController(_ controller: UIViewController, animated: Bool = true) {
        if let navController: UINavigationController = controller.navigationController, navController.viewControllers.count > 1 {
            if navController.topViewController === controller {
                navController.popViewController(animated: animated)
            }
        } else {
            if let presentingController: UIViewController = controller.presentingViewController {
                presentingController.dismiss(animated: animated, completion: nil)
            } else {
                assertionFailure("dismissViewController: attemt to dismiss not presented ViewController")
            }
        }
    }

    func dismissAllModalViewControllers(_ animated: Bool = true) {
        rootNavigationController.dismiss(animated: animated, completion: nil)
    }

    func setRootViewController(controller: UIViewController, animated: Bool = true) {
        rootViewController = controller
        rootNavigationController.setViewControllers([controller], animated: animated)
    }
}

// MARK: - Alerts

extension Router {

    func presentAlert(_ title: String?, message: String?, sender: UIViewController?, animated: Bool) {
        let action = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil)
        presentAlert(title,
                     message: message,
                     actions: [action],
                     sender: sender,
                     animated: animated)
    }

    func presentAlert(_ title: String?, message: String?, actions: [UIAlertAction], sender: UIViewController?, animated: Bool) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach({alertController.addAction($0)})
        let presentingController: UIViewController
        if let actualSender = sender {
            presentingController = actualSender.view.window != nil ? actualSender : rootNavigationController
        } else {
            presentingController = rootNavigationController
        }
        presentingController.present(alertController, animated: animated, completion: nil)
    }

    func presentActionSheet(_ title: String?,
                            message: String?,
                            actions: [UIAlertAction],
                            sender: UIViewController?,
                            popoverSourceView: UIView?,
                            animated: Bool) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        actions.forEach({alertController.addAction($0)})
        if let sourceView = popoverSourceView {
            alertController.modalPresentationStyle = .popover
            if let popoverPresentationController =  alertController.popoverPresentationController {
                popoverPresentationController.sourceView = sourceView
                popoverPresentationController.sourceRect = sourceView.bounds
            }
        }
        let presentingController: UIViewController
        if let actualSender = sender {
            presentingController = actualSender.view.window != nil ? actualSender : rootNavigationController
        } else {
            presentingController = rootNavigationController
        }
        presentingController.present(alertController, animated: animated, completion: nil)
    }
}

// MARK: - Error Handling

extension Router {

    func presentError(_ error: GenericAppError, sender: UIViewController?, animated: Bool) {
        presentError(error.errorDescription(), sender: sender, animated: animated)
    }

    func presentError(_ error: GenericAppError,
                      actions: [UIAlertAction],
                      sender: UIViewController?, animated: Bool) {
        presentError(error.errorDescription(),
                     actions: actions,
                     sender: sender,
                     animated: animated)
    }

    func presentError(_ errorMessage: String,
                      sender: UIViewController?,
                      animated: Bool) {
        let action = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil)
        presentError(errorMessage,
                     actions: [action],
                     sender: sender,
                     animated: animated)
    }

    func presentError(_ errorMessage: String,
                      actions: [UIAlertAction],
                      sender: UIViewController?,
                      animated: Bool) {
        presentAlert(NSLocalizedString("Oops!", comment: ""),
                     message: errorMessage,
                     actions: actions,
                     sender: sender,
                     animated: animated)
    }
}

// MARK: - Private

private extension UIViewController {
    func lookupCustomContainerViewControllerPresening() -> CustomContainerViewControllerPresening? {
        return (self as? CustomContainerViewControllerPresening) ?? self.customContainerViewController ?? self.parent?.lookupCustomContainerViewControllerPresening()
    }
}

