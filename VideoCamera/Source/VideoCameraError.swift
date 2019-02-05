//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import AVFoundation

public enum VideoCameraError: Error {

    case invalidConfiguration(message: String)
    case cantCreateSimulatedVideoBuffer(message: String)
    case unsupportedMetadataObjectType(type: AVMetadataObject.ObjectType)
    case captureSessionRuntimeError(underlyingError: Error?)
    case cantLockCameraForConfiguration(underlyingError: Error)
    case cantFlattenCapturedPhotoToData                         // image was captured, but image data can't be obtained (RAW image?)
    case cantSetCaptureSessionPreset(requested: AVCaptureSession.Preset, resolved: AVCaptureSession.Preset)
    case flashModeUnsupported(requestedMode: AVCaptureDevice.FlashMode)
    case torchModeUnsupported(requestedMode: AVCaptureDevice.TorchMode)
    case cameraIsUnavailable(cameraPosition: AVCaptureDevice.Position)
    case cantCreateDeviceInput(underlyingError: Error)
    case cantAttachVideoInput
    case photoOutputIsUnavailable
    case videoDataOutputIsUnavailable
    case metadataOutputIsUnavailable

}
