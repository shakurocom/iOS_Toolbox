//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit
import Lottie

public class ShakuroLogoPullToRefreshContentView: UIView {

    private enum Constant {
        static let defaultTargetPullLength: CGFloat = 100
        static let pullingJSONfilename: String = "animation-pulling-shakuro_logo.json"
        static let refreshingJSONfilename: String = "animation-refreshing-shakuro_logo.json"
    }

    private var pullingAnimationView: LOTAnimationView?
    private var refreshingAnimationView: LOTAnimationView?

    private var displayedState: PullToRefreshView.State?

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
        self.init(frame: CGRect(x: 0, y: 0, width: 320, height: Constant.defaultTargetPullLength))
    }

    private func commonInit() {
        if let jsonFilePath = Bundle.main.path(forResource: Constant.pullingJSONfilename, ofType: nil) {
            let animation = LOTAnimationView(filePath: jsonFilePath)
            animation.animationProgress = 0.0
            animation.translatesAutoresizingMaskIntoConstraints = false
            animation.frame = self.bounds
            self.addSubview(animation)
            if let animationSize = animation.sceneModel?.compBounds.size {
                animation.widthAnchor.constraint(equalTo: animation.heightAnchor, multiplier: animationSize.width / animationSize.height)
            }
            animation.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.0).isActive = true
            trailingAnchor.constraint(equalTo: animation.trailingAnchor, constant: 0.0).isActive = true
            animation.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0.0).isActive = true
            pullingAnimationView = animation
        } else {
            assertionFailure("ShakuroLogoPullToRefreshContentView: can't load animation: \(Constant.pullingJSONfilename)")
        }
        if let jsonFilePath = Bundle.main.path(forResource: Constant.refreshingJSONfilename, ofType: nil) {
            let animation = LOTAnimationView(filePath: jsonFilePath)
            animation.animationProgress = 0.0
            animation.loopAnimation = true
            animation.translatesAutoresizingMaskIntoConstraints = false
            animation.frame = self.bounds
            self.addSubview(animation)
            if let animationSize = animation.sceneModel?.compBounds.size {
                animation.widthAnchor.constraint(equalTo: animation.heightAnchor, multiplier: animationSize.width / animationSize.height)
            }
            animation.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.0).isActive = true
            trailingAnchor.constraint(equalTo: animation.trailingAnchor, constant: 0.0).isActive = true
            animation.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0.0).isActive = true
            refreshingAnimationView = animation
        } else {
            assertionFailure("ShakuroLogoPullToRefreshContentView: can't load animation: \(Constant.refreshingJSONfilename)")
        }
        setState(PullToRefreshView.State.idle, progress: 0.0)
    }

    // MARK: - Public

    public func length(forWidth: CGFloat) -> CGFloat {
        let result: CGFloat
        if let animationSize = pullingAnimationView?.sceneModel?.compBounds.size {
            result = (animationSize.height / animationSize.width) * forWidth
        } else {
            result = Constant.defaultTargetPullLength
        }
        return result
    }

    private func setState(_ newValue: PullToRefreshView.State, progress: CGFloat) {
        guard let pullingAnimation = pullingAnimationView,
            let refreshingAnimation = refreshingAnimationView
            else {
                return
        }
        switch newValue {
        case .idle, .readyToTrigger:
            if displayedState != newValue {
                pullingAnimation.isHidden = false
                refreshingAnimation.isHidden = true
                displayedState = newValue
            }
            pullingAnimation.animationProgress = progress
            print("state: \(newValue) progress: \(progress)")

        case .refreshing:
            if displayedState != newValue {
                // finish pulling animation, start refreshing animation
                if pullingAnimation.animationProgress < 1.0 {
                    pullingAnimation.isHidden = false
                    refreshingAnimation.isHidden = true
                    pullingAnimation.play(completion: { (finished: Bool) in
                        if finished {
                            pullingAnimation.isHidden = true
                            refreshingAnimation.isHidden = false
                            refreshingAnimation.play()
                        }
                    })
                } else {
                    pullingAnimation.isHidden = true
                    refreshingAnimation.isHidden = false
                    refreshingAnimation.play()
                }
                displayedState = newValue
            }

        case .finishing:
            if displayedState != newValue {
                pullingAnimation.isHidden = true
                refreshingAnimation.isHidden = false
                refreshingAnimation.pause()
                displayedState = newValue
            }
        }
    }

}

// MARK: - PullToRefreshContentViewProtocol

extension ShakuroLogoPullToRefreshContentView: PullToRefreshContentViewProtocol {

    public func updateState(currentPullDistance: CGFloat, targetPullDistance: CGFloat, state: PullToRefreshView.State) {
        setState(state, progress: min(max(currentPullDistance / targetPullDistance, 0.0), 1.0))
    }

}
