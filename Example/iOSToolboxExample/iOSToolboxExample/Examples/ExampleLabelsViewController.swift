//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

internal class ExampleLabelsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private enum Constant {
        static let tableCellID: String = "kExampleLabelsTableCellID"
    }

    @IBOutlet private var mainTableview: UITableView!

    private var example: Example?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title
        mainTableview.rowHeight = UITableView.automaticDimension
        mainTableview.delegate = self
        mainTableview.dataSource = self
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.tableCellID, for: indexPath)
        // NOTE: generation of new labels is done inside cell itself - see 'awake' and 'prepare for reuse'
        return cell
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExampleLabelsViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleLabelsViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleLabelsViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}

internal class ExampleLabelsTableCell: UITableViewCell {

    @IBOutlet private var labels: [InsetsLabel] = []

    override func awakeFromNib() {
        for label in labels {
            label.cornerRadius = 4
            label.backgroundColor = UIColor.white
            label.roundedBackgroundColor = UIColor.purple
        }
        changeTexts()
    }
    override func prepareForReuse() {
        changeTexts()
    }

    private func changeTexts() {
        let words = [
            "linguistics",
            "word",
            "smallest",
            "element",
            "that",
            "can",
            "uttered",
            "isolation",
            "with",
            "objective",
            "practical",
            "meaning"
        ]
        for label in labels {
            label.text = words[Int(arc4random()) % words.count]
        }
    }

}
