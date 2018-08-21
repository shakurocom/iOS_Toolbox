//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import AVFoundation
import UIKit

/**
 Initial configuration for video camera.
 */
public struct VideoCameraConfiguration {

    // MARK: Generic
    public var flashColor: UIColor?
    public var flashAnimationDuration: CFTimeInterval?
    public weak var cameraDelegate: VideoCameraDelegate?

    // MARK: Simulator-only
    public var simulatedImage: CGImage?
    public var simulatedVideoFeedOrientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait
    public var simulatedVideoFeedFrameInterval: DispatchTimeInterval = .milliseconds(1000 / 30) // 30 FPS
    public weak var simulatedVideoFeedDelegate: VideoCameraSimulatedVideoDataOutputHandler?
    public var photoCaptureSimulatorFallbackBlock: ((_ photo: CGImage) -> Void)? = nil // this block will be used on simulator, when you call `func capturePhoto(delegate:)`

    // MARK: Device-only

    /**
     Camera position. `AVCaptureDevice.Position.unspecified` will result in error.
     Default value is `AVCaptureDevice.Position.back`.
     */
    public var cameraPosition: AVCaptureDevice.Position = AVCaptureDevice.Position.back

    /**
     Capture session preset. Settings for current capture session.
     Default value is `AVCaptureSession.Preset.photo`
     */
    public var captureSessionPreset: AVCaptureSession.Preset = AVCaptureSession.Preset.photo

    /**
     Whether capturing of photos (still images) is enabled.
     Default value is `true`.
     */
    public var capturePhotoEnabled: Bool = true

    /**
     Settings for capturing of photos. See `AVCapturePhotoSettings` for details.
     Default value is image in JPEG encoding.
     */
    public var capturePhotoSettings: AVCapturePhotoSettings = {
        if #available(iOS 11.0, *) {
            return AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            return AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
        }
    }()

    /**
     Before each photo is made, device orientation has to be set. Otherwise image will have incorrect orientation in metadata.
     - `true` - accelerometer will be used to detect device orientation
     - `false` - `UIDevice.current.orientation`
     */
    public var usePreciseOrientationDetectionMethod: Bool = true

    /**
     Whether video capturing is enabled.
     Default value is `true`
     */
    public var videoFeedEnabled: Bool = true

    public var videoFeedShouldDiscardLateFrames: Bool = true

    /**
     Settings for video feed output.
     Popular values are `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange` and `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`.
     See `AVCaptureVideoDataOutput` for details and available settings.
     Default value is "return video feed buffer in 32BGRA pixel format".
     */
    public var videoFeedSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

    public weak var videoFeedDelegate: AVCaptureVideoDataOutputSampleBufferDelegate? = nil

    /**
     Whether metadata feed is enabled.
     Default vale is `true`.
     */
    public var metadataFeedEnabled: Bool = true

    public var metadataObjectTypes: [AVMetadataObject.ObjectType] = []

    public var metadataFeedDelegate: AVCaptureMetadataOutputObjectsDelegate? = nil

    public init() {}

}
