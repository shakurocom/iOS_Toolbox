//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

internal class VideoCameraPreviewView: UIView {

    private var flashLayer: CALayer?
    private var flashAnimationDuration: CFTimeInterval?

    // MARK: - Initialization

    required init?(coder aDecoder: NSCoder) {
        fatalError("VideoCameraPreviewView: use 'init(frame:flashColor:flashAnimationDuration:)'")
    }

    internal init(frame: CGRect, flashColor: UIColor?, flashAnimationDuration aFlashAnimationDuration: CFTimeInterval?) {
        super.init(frame: frame)

        if let actualFlashColor = flashColor, let animationDuration = aFlashAnimationDuration {
            let tempFlashLayer = CALayer()
            tempFlashLayer.backgroundColor = actualFlashColor.cgColor
            tempFlashLayer.opacity = 0.0
            layer.addSublayer(tempFlashLayer)
            flashLayer = tempFlashLayer
            flashAnimationDuration = animationDuration
        } else {
            self.flashLayer = nil
            self.flashAnimationDuration = nil
        }
    }

    // MARK: - Events

    override func layoutSubviews() {
        super.layoutSubviews()

        flashLayer?.frame = bounds
    }

    // MARK: - Public

    internal func animateFlash() {
        guard let actualFlashLayer = flashLayer, let animationDuration = flashAnimationDuration else {
            return
        }

        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [
            NSNumber(value: actualFlashLayer.presentation()?.opacity ?? 0.0),
            NSNumber(value: Float(1.0)),
            NSNumber(value: Float(0.0))
        ]
        animation.keyTimes = [
            NSNumber(value: Float(0.0)),
            NSNumber(value: Float(0.5)),
            NSNumber(value: Float(1.0))
        ]
        animation.duration = animationDuration
        flashLayer?.add(animation, forKey: "opacity_anim")
    }

}
