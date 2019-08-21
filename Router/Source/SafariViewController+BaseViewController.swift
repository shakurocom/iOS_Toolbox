//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//

import UIKit
import SafariServices

struct SafariViewControllerOptions {
    static let validSchema: [String] = ["http", "https"]

    let URI: URL

    private(set) weak var delegate: SFSafariViewControllerDelegate?

    func canOpentViaSafariViewController() -> Bool {
        return ["http", "https"].contains(URI.scheme?.lowercased() ?? "")
    }
}

final class SafariViewController: SFSafariViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

extension SFSafariViewController {

    static func present(_ sender: UIViewController,
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
