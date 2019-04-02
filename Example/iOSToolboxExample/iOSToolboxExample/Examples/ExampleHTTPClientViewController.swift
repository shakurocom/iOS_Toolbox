//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

// https://www.random.org/strings/?num=10&len=10&digits=on&unique=on&format=plain&rnd=new
internal enum RandomOrgAPIEndpoint: HTTPClientAPIEndPoint {

    private static let APIBaseURLString = "https://www.random.org"

    case strings

    public func urlString() -> String {
        switch self {
        case .strings:
            return "\(RandomOrgAPIEndpoint.APIBaseURLString)/strings"
        }
    }

}

internal class StringsParser: HTTPClientParserProtocol {

    typealias ResultType = String
    typealias ResponseValueType = String

    static func generateResponseDataDebugDescription(_ responseData: Data) -> String? {
        return serializeResponseData(responseData)
    }

    static func serializeResponseData(_ responseData: Data) -> String? {
        return String(data: responseData, encoding: String.Encoding.utf8)
    }

    static func parseObject(_ object: String, response: HTTPURLResponse?) -> String? {
        return object
    }

    static func parseError(_ object: String?, response: HTTPURLResponse?, responseData: Data?) -> Error? {
        return nil
    }

}

private struct VoidSession: HTTPClientUserSession {

    func httpHeaders() -> [String: String] {
        return [:]
    }

}

// MARK: - ExampleHTTPClientViewController

internal class ExampleHTTPClientViewController: UIViewController {

    private enum State {
        case data(strings: String)
        case refreshing
    }

    @IBOutlet private var requestDataButton: UIButton!
    @IBOutlet private var resultsTitleLabel: UILabel!
    @IBOutlet private var resultsValueLabel: UILabel!
    @IBOutlet private var spinner: UIActivityIndicatorView!

    private var example: Example?
    private var randomOrgClient: HTTPClient?
    private var state: State = .data(strings: "")

    // MARK: Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title

        requestDataButton.isExclusiveTouch = true
        requestDataButton.titleLabel?.numberOfLines = 0
        requestDataButton.titleLabel?.textAlignment = .center
        requestDataButton.setTitle("Request some strings\nfrom random.org", for: UIControl.State.normal)

        updateUI(newState: .data(strings: ""))

        randomOrgClient = HTTPClient(
            name: "RandomOrgClient",
            acceptableContentTypes: ["text/plain"])
    }

    // MARK: Interface callbacks

    @IBAction private func requestDataButtonTapped() {
        guard case ExampleHTTPClientViewController.State.data = state else {
            return
        }

        updateUI(newState: ExampleHTTPClientViewController.State.refreshing)

        var requestOptions = HTTPClient.RequestOptions(
            method: HTTPClient.RequestMethod.GET,
            endpoint: RandomOrgAPIEndpoint.strings,
            parser: StringsParser.self)
        requestOptions.parameters = [
            "num": "10",
            "len": "10",
            "digits": "on",
            "unique": "on",
            "format": "plain",
            "rnd": "new"
        ]
        requestOptions.completionHandler = { (parsedResponse, _) in
            DispatchQueue.main.async(execute: {
                let stringsValue: String
                switch parsedResponse {
                case .success(let networkResult):
                    stringsValue = networkResult
                case .cancelled:
                    stringsValue = "# REQUEST WAS CANCELLED #"
                case .failure(let networkError):
                    stringsValue = "# ERROR: #\n\(networkError)"
                }
                self.updateUI(newState: ExampleHTTPClientViewController.State.data(strings: stringsValue))
            })
        }
        _ = randomOrgClient?.sendRequest(options: requestOptions)
    }

    // MARK: Private

    private func updateUI(newState: State) {
        state = newState
        switch state {
        case .data(let strings):
            resultsValueLabel.isHidden = false
            resultsValueLabel.text = strings
            view.layoutIfNeeded()
            spinner.stopAnimating()
        case .refreshing:
            resultsValueLabel.isHidden = true
            spinner.startAnimating()
        }
    }

}

// MARK: ExampleViewControllerProtocol

extension ExampleHTTPClientViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleHTTPClientViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleHTTPClientViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
