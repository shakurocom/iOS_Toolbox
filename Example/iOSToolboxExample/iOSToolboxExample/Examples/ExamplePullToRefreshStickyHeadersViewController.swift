//
//
//

import UIKit

internal class ExamplePullToRefreshStickyHeadersViewController: UIViewController {

    private enum Constant {
        static let cellID: String = "kTableCellID"
        static let refreshDelay: DispatchTimeInterval = DispatchTimeInterval.milliseconds(10000)
    }

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var mainTableView: UITableView!
    @IBOutlet private var manualRefeshButton: UIButton!
    private var refreshControl: PullToRefreshView!

    private var example: Example?
    private var dataModel: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title

        mainTableView.dataSource = self
        mainTableView.delegate = self
        mainTableView.rowHeight = UITableView.automaticDimension

        refreshControl = PullToRefreshView(
            scrollView: mainTableView,
            length: ExamplePullToRefreshContentView.length(),
            contentView: ExamplePullToRefreshContentView(),
            useTableViewHeader: true)

        refreshControl.eventHandler = { [weak self] in
            self?.fetchData()
        }
    }

    // MARK: - Interface callbacks

    @IBAction private func manualRefreshButtonTapped() {
        refreshControl.trigger()
    }

    // MARK: - Private

    private func fetchData() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Constant.refreshDelay, execute: {
            self.dataModel += 1
            self.refreshControl.endRefreshingAnimation()
            //self.mainTableView.reloadData()
        })
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ExamplePullToRefreshStickyHeadersViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 40))
        header.backgroundColor = UIColor.gray
        let headerLabel = UILabel(frame: header.bounds)
        headerLabel.text = "header \(section)"
        headerLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.addSubview(headerLabel)
        return header
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.cellID, for: indexPath)
        if let exampleCell = cell as? ExamplePullToRefreshLeftCell {
            exampleCell.setup(message: String(format: NSLocalizedString("%i. Number of completed refreshes: %i", comment: ""), indexPath.row, dataModel))
        } else {
            assertionFailure("ExamplePullToRefreshViewController: cell of unexpected class.")
        }
        return cell
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExamplePullToRefreshStickyHeadersViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: self))
        let exampleVC: ExamplePullToRefreshStickyHeadersViewController = storyboard
            .instantiateViewController(withIdentifier: "kExamplePullToRefreshStickyHeadersViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
