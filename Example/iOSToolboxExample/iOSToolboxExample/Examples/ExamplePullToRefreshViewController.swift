//
//
//

import UIKit

internal class ExamplePullToRefreshViewController: UIViewController {

    private enum Constant {
        static let cellID: String = "kLeftTableCellID"
        static let leftRefreshDelay: DispatchTimeInterval = DispatchTimeInterval.milliseconds(2000)
        static let rightRefreshDelay: DispatchTimeInterval = DispatchTimeInterval.milliseconds(2000)
    }

    @IBOutlet private var leftContainerView: UIView!
    @IBOutlet private var leftTableView: UITableView!
    @IBOutlet private var leftRefeshButton: UIButton!
    private var leftRefreshControl: PullToRefreshView!

    @IBOutlet private var rightContainerView: UIView!
    @IBOutlet private var rightScrollView: UIScrollView!
    @IBOutlet private var rightRefreshButton: UIButton!
    @IBOutlet private var rightContentLabel: UILabel!
    private var rightRefreshControl: PullToRefreshView!

    private var example: Example?
    private var leftDataModel: Int = 0
    private var rightDataModel: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title

        leftTableView.rowHeight = UITableView.automaticDimension
        leftRefreshControl = PullToRefreshView(
            scrollView: leftTableView,
            length: ExamplePullToRefreshContentView.length(),
            contentView: ExamplePullToRefreshContentView())
        leftRefreshControl.eventHandler = { [weak self] in
            self?.fetchDataLeft()
        }

        rightRefreshControl = PullToRefreshView(
            scrollView: rightScrollView,
            length: ExamplePullToRefreshContentView.length(),
            contentView: ExamplePullToRefreshContentView())
        rightRefreshControl.eventHandler = { [weak self] in
            self?.fetchDataRight()
        }
        rightRefreshControl.adjustsOffsetToVisible = true

        leftTableView.reloadData()
        updateRightContent()
    }

    // MARK: - Interface callbacks

    @IBAction private func leftRefreshButtonTapped() {
        leftRefreshControl.trigger()
    }

    @IBAction private func rightRefreshButtonTapped() {
        rightRefreshControl.trigger()
    }

    // MARK: - Private

    private func fetchDataLeft() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Constant.leftRefreshDelay, execute: {
            self.leftDataModel += 1
            self.leftRefreshControl.endRefreshingAnimation()
            self.leftTableView.reloadData()
        })
    }

    private func fetchDataRight() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Constant.rightRefreshDelay, execute: {
            self.rightDataModel += 1
            self.rightRefreshControl.endRefreshingAnimation()
            self.updateRightContent()
        })
    }

    private func updateRightContent() {
        rightContentLabel.text = String(format: NSLocalizedString("Number of completed refreshes: %i", comment: ""), rightDataModel)
        rightScrollView.layoutIfNeeded()
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ExamplePullToRefreshViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.cellID, for: indexPath)
        if let exampleCell = cell as? ExamplePullToRefreshLeftCell {
            exampleCell.setup(message: String(format: NSLocalizedString("%i. Number of completed refreshes: %i", comment: ""), indexPath.row, leftDataModel))
        } else {
            assertionFailure("ExamplePullToRefreshViewController: cell of unexpected class.")
        }
        return cell
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExamplePullToRefreshViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: self))
        let exampleVC: ExamplePullToRefreshViewController = storyboard.instantiateViewController(withIdentifier: "kExamplePullToRefreshViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}

// MARK: - ExamplePullToRefreshLeftCell

internal class ExamplePullToRefreshLeftCell: UITableViewCell {

    @IBOutlet private var titleLabel: UILabel!

    internal func setup(message: String) {
        titleLabel.text = message
        self.layoutIfNeeded()
    }

}
