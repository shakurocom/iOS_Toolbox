//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//

import UIKit
import SafariServices

public struct SafariViewControllerOptions {
    static let validSchema: [String] = ["http", "https"]

    public let URI: URL

    private(set) weak public var delegate: SFSafariViewControllerDelegate?

    public func canOpentViaSafariViewController() -> Bool {
        return ["http", "https"].contains(URI.scheme?.lowercased() ?? "")
    }
}

public final class SafariViewController: SFSafariViewController {

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

extension SFSafariViewController {

    public static func present(_ sender: UIViewController,
                               router: RouterProtocol,
                               options: SafariViewControllerOptions) -> SFSafariViewController? {
        let controller: SafariViewController = SafariViewController(url: options.URI)
        controller.delegate = options.delegate
        return router.presentViewController(controller: controller,
                                            from: sender,
                                            style: .modalDefault,
                                            animated: true) as? SFSafariViewController
    }
}
