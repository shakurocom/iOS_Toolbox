//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit
import Accelerate
import AVFoundation

/**
 Camera authorization status will be requested upon initialization in background thread.
 */
public protocol VideoCamera {

    var isInitialized: Bool { get }
    var cameraAuthrizationStatus: AVAuthorizationStatus { get }

    var previewView: UIView { get }

    var hasFlash: Bool { get } // `false` if camera is not initialized
    var flashMode: AVCaptureDevice.FlashMode { get set } // `.off` will be returned, if camera is not initialized
    func setNextFlashMode()

    var hasTorch: Bool { get }
    var torchMode: AVCaptureDevice.TorchMode { get set } // `.off` will be returned, if camera is not initialized
    func selectNextTorchMode()

    func setDesiredFrameRate(_ frameRate: CMTimeScale) // has no effect on simulator - use `VideoCameraConfiguration.simulatedVideoFeedFrameInterval`
    var whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode { get set } // will return `AVCaptureDevice.WhiteBalanceMode.locked` if camera is not initialized
    var automaticallyEnablesLowLightBoostWhenAvailable: Bool { get set }

    var focusPointOfInterest: CGPoint { get }
    func setFocusMode(_ mode: AVCaptureDevice.FocusMode, atPoint point: CGPoint)
    var smoothAutoFocusEnabled: Bool { get set }
    var autoFocusRangeRestriction: AVCaptureDevice.AutoFocusRangeRestriction { get set }

    var videoDataOutputSize: CGSize { get }
    var videoDataOutputOrientation: AVCaptureVideoOrientation { get }

    func startSession() // if authorization was changed - camera will try to initialize itself before starting session
    func stopSession()
    func setVideoPreviewPaused(_ paused: Bool)

    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate)  // full-power method
    func capturePhoto(completionBlock: @escaping (_ imageData: Data?, _ error: Error?) -> Void)    // convinience method with easy-to-use completion block

    var metadataRectOfInterest: CGRect { get set }          // in coordinates of preview view
    func transformedMetadataObject(_ metadataObject: AVMetadataObject) -> AVMetadataObject? // transform metadata object into preview layer's coordinates

}

public protocol VideoCameraSimulatedVideoDataOutputHandler: class {
    func process(imageBuffer: CVImageBuffer, orientation: AVCaptureVideoOrientation)
}

/**
 Delegate will be called from background thread.
 */
public protocol VideoCameraDelegate: class {
    func videoCamera(_ videoCamera: VideoCamera, error: Error)  // error was encountered
    func videoCameraInitialized(_ videoCamera: VideoCamera, errors: [VideoCameraError])     // initialization finished. Errors returned here are not critical
    func videoCamera(_ videoCamera: VideoCamera, authorizationStatusChanged newValue: AVAuthorizationStatus)
    func videoCamera(_ videoCamera: VideoCamera, flashModeForPhotoDidChanged newValue: AVCaptureDevice.FlashMode)
    func videoCamera(_ videoCamera: VideoCamera, torchModeDidChanged newValue: AVCaptureDevice.TorchMode)
    func videoCamera(_ videoCamera: VideoCamera, focusPointOfInterestDidChanged newValue: CGPoint)
    func videoCameraWillCapturePhoto(_ videoCamera: VideoCamera)
    func videoCameraDidFinishCapturingPhoto(_ videoCamera: VideoCamera, error: Error?)
    func videoCameraDidFinishRecordingLivePhoto(_ videoCamera: VideoCamera, url: URL)
    func videoCameraDidFinishProcessingLivePhoto(_ videoCamera: VideoCamera, url: URL, duration: CMTime, photoDisplayTime: CMTime, error: Error?)
}
