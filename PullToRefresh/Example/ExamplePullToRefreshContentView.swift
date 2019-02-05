//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

public class ExamplePullToRefreshContentView: UIView {

    private enum Constant {
        static let targetPullLength: CGFloat = 50.0
    }

    private var titleLabel: UILabel?
    private var isAnimating: Bool = false
    private var currentDisplayedState: PullToRefreshView.State?

    // MARK: - Initialization

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 300, height: Constant.targetPullLength))
    }

    private func commonInit() {
        self.backgroundColor = UIColor.magenta.withAlphaComponent(0.4)
        self.isOpaque = false

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 23))
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        label.setContentHuggingPriority(UILayoutPriority(251), for: NSLayoutConstraint.Axis.horizontal)
        label.setContentHuggingPriority(UILayoutPriority(251), for: NSLayoutConstraint.Axis.vertical)
        label.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        titleLabel = label

        isAnimating = false
    }

    // MARK: - Public

    public static func length() -> CGFloat {
        return Constant.targetPullLength
    }

    private func setState(_ newValue: PullToRefreshView.State) {
        if newValue != currentDisplayedState {
            currentDisplayedState = newValue
            switch newValue {
            case .idle:
                titleLabel?.text = "idle"
            case .readyToTrigger:
                titleLabel?.text = "readyToTrigger"
            case .refreshing:
                titleLabel?.text = "refreshing"
            case .finishing:
                titleLabel?.text = "finishing"
            }
            self.layoutIfNeeded()
        }
    }

}

// MARK: - PullToRefreshContentViewProtocol

extension ExamplePullToRefreshContentView: PullToRefreshContentViewProtocol {

    public func updateState(currentPullDistance: CGFloat, targetPullDistance: CGFloat, state: PullToRefreshView.State) {
        setState(state)
    }

}
