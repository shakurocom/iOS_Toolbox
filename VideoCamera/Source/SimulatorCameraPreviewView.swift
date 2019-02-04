//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

internal class SimulatorCameraPreviewView: VideoCameraPreviewView {

    private let imageLayer: CALayer

    // MARK: - Initialization

    required init?(coder aDecoder: NSCoder) {
        fatalError("SimulatorCameraPreviewView: use init(frame:,flashColor:,flashAnimationDuration:,image:)")
    }

    required init(frame: CGRect, flashColor: UIColor?, flashAnimationDuration aFlashAnimationDuration: CFTimeInterval?, image: CGImage) {
        imageLayer = CALayer()
        imageLayer.backgroundColor = UIColor.clear.cgColor
        imageLayer.contentsGravity = CALayerContentsGravity.resizeAspect
        imageLayer.contents = image

        super.init(frame: frame, flashColor: flashColor, flashAnimationDuration: aFlashAnimationDuration)

        imageLayer.frame = bounds
        layer.insertSublayer(imageLayer, at: 0)
    }

    // MARK: - Events

    override func layoutSubviews() {
        super.layoutSubviews()

        imageLayer.frame = bounds
    }

    // MARK: - Public

    internal func setImageHidden(_ imageHidden: Bool) {
        imageLayer.isHidden = imageHidden
    }

}
