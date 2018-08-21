//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import AVFoundation
import UIKit

internal class DeviceCameraPreviewView: VideoCameraPreviewView {

    private var previewLayer: AVCaptureVideoPreviewLayer

    // MARK: - Initialization

    required init?(coder aDecoder: NSCoder) {
        fatalError("DeviceCameraPreviewView: use init(frame:flashColor:flashAnimationDuration:)")
    }

    required override init(frame: CGRect, flashColor: UIColor?, flashAnimationDuration aFlashAnimationDuration: CFTimeInterval?) {
        previewLayer = AVCaptureVideoPreviewLayer()

        super.init(frame: frame, flashColor: flashColor, flashAnimationDuration: aFlashAnimationDuration)

        previewLayer.frame = bounds
        self.layer.insertSublayer(previewLayer, at: 0)
    }

    // MARK: - Events

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }

    // MARK: - Public

    internal func setCaptureSession(_ session: AVCaptureSession) {
        DispatchQueue.main.async(execute: {
            self.previewLayer.removeFromSuperlayer()
            self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
            self.previewLayer.frame = self.bounds
            self.layer.insertSublayer(self.previewLayer, at: 0)
        })
    }

    internal func setVideoPreviewPaused(_ paused: Bool) {
        previewLayer.connection?.isEnabled = !paused
    }

    internal func transformedMetadataObject(_ metadataObject: AVMetadataObject) -> AVMetadataObject? {
        return previewLayer.transformedMetadataObject(for: metadataObject)
    }

    internal func metadataOutputRectConverted(fromLayerRect: CGRect) -> CGRect {
        return previewLayer.metadataOutputRectConverted(fromLayerRect: fromLayerRect)
    }

    internal func layerRectConverted(fromMetadataOutputRect rectInMetadataOutputCoordinates: CGRect) -> CGRect {
        return previewLayer.layerRectConverted(fromMetadataOutputRect: rectInMetadataOutputCoordinates)
    }
    
}
