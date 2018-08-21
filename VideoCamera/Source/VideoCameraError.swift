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

    public func errorDescription() -> String {
        switch self {
        case .invalidConfiguration(let message):
            return "Invalid configuration: " + message

        case .cantCreateSimulatedVideoBuffer(let message):
            return "Can't create simulated video buffer: " + message

        case .unsupportedMetadataObjectType(let type):
            return "Metadata object type '\(type)' unsupported"

        case .captureSessionRuntimeError(let underlyingError):
            let underlyingDescription: String
            if let actualError = underlyingError {
                underlyingDescription = actualError.localizedDescription
            } else {
                underlyingDescription = "NIL"
            }
            return "Capture session runtime error: \(underlyingDescription)"

        case .cantLockCameraForConfiguration(let underlyingError):
            return "Can't lock camera device for cnfiguration: \(underlyingError)"

        case .cantFlattenCapturedPhotoToData:
            return "Can't convert captured photo to 'Data' representation"

        case .cantSetCaptureSessionPreset(let requested, let resolved):
            return "Requested capture preset '\(requested)' is unavailable. Resolved into '\(resolved)'"

        case .flashModeUnsupported(let requestedMode):
            return "Flash mode '\(requestedMode)' is unavailable"

        case .torchModeUnsupported(let requestedMode):
            return "Torch mode '\(requestedMode)' is unavailable"

        case .cameraIsUnavailable(let cameraPosition):
            return "Camera at position '\(cameraPosition)' is not found."

        case .cantCreateDeviceInput(let underlyingError):
            return "Cant initialize device input for capture session: \(underlyingError.localizedDescription)"

        case .cantAttachVideoInput:
            return "Cant attach video input to capture session."

        case .photoOutputIsUnavailable:
            return "Photo output is unavailable."

        case .videoDataOutputIsUnavailable:
            return "Video data output is unavailable."

        case .metadataOutputIsUnavailable:
            return "Metadta output is unavailable."
        }
    }

}
