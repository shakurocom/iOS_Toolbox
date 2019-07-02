//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

internal class ExampleSelectorViewController: UIViewController {

    private let examples: [Example] = Example.all()

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Examples"
    }

}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ExampleSelectorViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return examples.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "kExampleCellID", for: indexPath)
        let example = examples[indexPath.row]
        cell.textLabel?.text = example.title
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let example = examples[indexPath.row]
        let exampleVC = example.instantiateViewController()
        navigationController?.pushViewController(exampleVC, animated: true)
    }

}
