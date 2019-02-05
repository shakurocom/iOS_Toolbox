//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

internal class ExamplePullToRefreshShakuroLogoViewController: UIViewController {

    private enum Constant {
        static let fetchDelay: DispatchTimeInterval = DispatchTimeInterval.seconds(6)
    }

    @IBOutlet private var mainScrollView: UIScrollView!
    private var refreshControl: PullToRefreshView!

    private var example: Example?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = example?.title

        mainScrollView.alwaysBounceVertical = true
        let logoContentView = ShakuroLogoPullToRefreshContentView()
        refreshControl = PullToRefreshView(
            scrollView: mainScrollView,
            length: logoContentView.length(forWidth: UIScreen.main.bounds.size.width),
            contentView: logoContentView)
        refreshControl.eventHandler = { [weak self] in
            self?.fetchData()
        }
    }

    private func fetchData() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Constant.fetchDelay, execute: { [weak self] in
            self?.refreshControl.endRefreshingAnimation()
        })
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExamplePullToRefreshShakuroLogoViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: self))
        let exampleVC: ExamplePullToRefreshShakuroLogoViewController = storyboard.instantiateViewController(withIdentifier: "kExamplePullToRefreshShakuroLogoViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
