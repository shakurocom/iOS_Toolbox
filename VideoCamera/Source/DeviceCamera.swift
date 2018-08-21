//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit
import AVFoundation

internal class DeviceCamera: NSObject {

    private enum InitializationStatus {
        case notInitialized
        case initialized
        case initializationError
        case waitingForAuthorization
    }

    // delayed init
    private var initialConfiguration: VideoCameraConfiguration?

    // general
    private weak var delegate: VideoCameraDelegate?
    private let workQueue: DispatchQueue
    private var cameraDevice: AVCaptureDevice?
    private var cameraDevicePosition: AVCaptureDevice.Position = AVCaptureDevice.Position.unspecified
    private var cameraDeviceInitializationStatus: InitializationStatus = .notInitialized
    private var captureInput: AVCaptureDeviceInput?
    private var captureSession: AVCaptureSession?
    private var notificationTokens: [NSObjectProtocol]
    private var observationTokens: [NSKeyValueObservation]
    private var authorizationForVideo: AVAuthorizationStatus = AVAuthorizationStatus.notDetermined
    private var cameraShouldStartSessionAfterInitialization: Bool = false

    // preview
    private let cameraPreviewView: DeviceCameraPreviewView

    // still images (photos)
    private var photoOutput: AVCapturePhotoOutput?
    private var photoOutputSettings: AVCapturePhotoSettings?
    private var isCapturingPhoto: Bool = false
    private var capturePhotoCompletionBlock: ((_ imageData: Data?, _ error: Error?) -> Void)?
    private var useDeviceOrientationListener: Bool = false
    private var deviceOrientationListener: DeviceOrientationListener?

    // video feed
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var videoDataOutputQueue: DispatchQueue?

    // metadata feed
    private var metadataOutput: AVCaptureMetadataOutput?
    private var metadataOutputQueue: DispatchQueue?

    // MARK: - Initialization

    internal init(configuration: VideoCameraConfiguration) {
        initialConfiguration = configuration
        delegate = configuration.cameraDelegate
        workQueue = DispatchQueue(label: "com.shakuro.devicecamera.workqueue")
        cameraPreviewView = DeviceCameraPreviewView(
            frame: CGRect(x: 0, y: 0, width: 100, height: 100),
            flashColor: configuration.flashColor,
            flashAnimationDuration: configuration.flashAnimationDuration)
        notificationTokens = []
        observationTokens = []

        super.init()

        // delayed initialization
        workQueue.async(execute: {
            self.authorizedSetup()
        })
    }

    deinit {
        let center = NotificationCenter.default
        for token in notificationTokens {
            center.removeObserver(token)
        }
    }

    private func setupCaptureSession(configuration aConfiguration: VideoCameraConfiguration?) {
        guard let configuration = aConfiguration,
            configuration.cameraPosition != .unspecified else {
            delegate?.videoCamera(self, error: VideoCameraError.invalidConfiguration(message: "'cameraPosition' can't have 'AVCaptureDevice.Position.unspecified' value"))
            return
        }

        // get camera
        guard let camera = getCamera(position: configuration.cameraPosition) else {
            delegate?.videoCamera(self, error: VideoCameraError.cameraIsUnavailable(cameraPosition: configuration.cameraPosition))
            return
        }

        // input from camera device
        let deviceInput: AVCaptureDeviceInput
        do {
            deviceInput = try AVCaptureDeviceInput(device: camera)
        } catch let error {
            delegate?.videoCamera(self, error: VideoCameraError.cantCreateDeviceInput(underlyingError: error))
            return
        }

        setCameraDevice(camera)
        cameraDevicePosition = configuration.cameraPosition
        captureInput = deviceInput

        // capture session
        let session = AVCaptureSession()
        captureSession = session
        if session.canSetSessionPreset(configuration.captureSessionPreset) {
            session.sessionPreset = configuration.captureSessionPreset
        } else {
            delegate?.videoCamera(self, error: VideoCameraError.cantSetCaptureSessionPreset(requested: configuration.captureSessionPreset,
                                                                                            resolved: session.sessionPreset))
        }
        let token = NotificationCenter.default.addObserver(
            forName: Notification.Name.AVCaptureSessionRuntimeError,
            object: nil,
            queue: nil,
            using: { [weak self] (notification: Notification) in
                if let strongSelf = self {
                    if let error: Error = notification.userInfo?[AVCaptureSessionErrorKey] as? Error {
                        strongSelf.delegate?.videoCamera(strongSelf, error: VideoCameraError.captureSessionRuntimeError(underlyingError: error))
                    } else {
                        strongSelf.delegate?.videoCamera(strongSelf, error: VideoCameraError.captureSessionRuntimeError(underlyingError: nil))
                    }
                }
        })
        notificationTokens.append(token)
        cameraPreviewView.setCaptureSession(session)
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)

            var nonCriticalErrors: [VideoCameraError] = []

            // photos output
            if configuration.capturePhotoEnabled {
                let output = AVCapturePhotoOutput()
                photoOutput = output
                photoOutputSettings = configuration.capturePhotoSettings
                if session.canAddOutput(output) {
                    session.addOutput(output)
                } else {
                    nonCriticalErrors.append(VideoCameraError.photoOutputIsUnavailable)
                }
                useDeviceOrientationListener = configuration.usePreciseOrientationDetectionMethod
                if useDeviceOrientationListener {
                    deviceOrientationListener = DeviceOrientationListener()
                    deviceOrientationListener?.beginListeningDeviceOrientation()
                }
            }

            // video data output
            if configuration.videoFeedEnabled {
                videoDataOutputQueue = DispatchQueue(label: "com.shakuro.devicecamera.videofeedqueue")
                let output = AVCaptureVideoDataOutput()
                output.alwaysDiscardsLateVideoFrames = configuration.videoFeedShouldDiscardLateFrames
                output.videoSettings = configuration.videoFeedSettings
                output.setSampleBufferDelegate(configuration.videoFeedDelegate, queue: videoDataOutputQueue)
                if session.canAddOutput(output) {
                    session.addOutput(output)
                } else {
                    nonCriticalErrors.append(VideoCameraError.videoDataOutputIsUnavailable)
                }
                videoDataOutput = output
            }

            // metadata output
            if configuration.metadataFeedEnabled {
                metadataOutputQueue = DispatchQueue(label: "com.shakuro.devicecamera.metadatafeedqueue")
                let output = AVCaptureMetadataOutput()
                output.setMetadataObjectsDelegate(configuration.metadataFeedDelegate, queue: metadataOutputQueue)
                if session.canAddOutput(output) {
                    session.addOutput(output)
                } else {
                    nonCriticalErrors.append(VideoCameraError.metadataOutputIsUnavailable)
                }
                var validObjectTypes: [AVMetadataObject.ObjectType] = []
                for type in configuration.metadataObjectTypes {
                    if output.availableMetadataObjectTypes.contains(type) {
                        validObjectTypes.append(type)
                    } else {
                        nonCriticalErrors.append(VideoCameraError.unsupportedMetadataObjectType(type: type))
                    }
                }
                output.metadataObjectTypes = validObjectTypes
                metadataOutput = output
            }

            // done
            cameraDeviceInitializationStatus = .initialized
            if cameraShouldStartSessionAfterInitialization {
                cameraShouldStartSessionAfterInitialization = false
                startSession()
            }
            delegate?.videoCameraInitialized(self, errors: nonCriticalErrors)
        } else {
            cameraDeviceInitializationStatus = .initializationError
            delegate?.videoCamera(self, error: VideoCameraError.cantAttachVideoInput)
        }
        initialConfiguration = nil
    }

    // MARK: - Private

    private func authorizedSetup() {
        guard (cameraDeviceInitializationStatus == .notInitialized) || (cameraDeviceInitializationStatus == .waitingForAuthorization) else {
            return
        }

        let status = VideoCameraFactory.authorizationStatusForVideo()
        videoAuthorizationStatusChanged(to: status)
        switch status {
        case .notDetermined:
            VideoCameraFactory.requestAuthorizationForVideo(completion: { (authGranted: Bool) in
                self.workQueue.async(execute: {
                    if authGranted {
                        self.videoAuthorizationStatusChanged(to: .authorized)
                        self.setupCaptureSession(configuration: self.initialConfiguration)
                    } else {
                        self.videoAuthorizationStatusChanged(to: .denied)
                        // do nothing - we will try to check authorization on 'startSession'
                    }
                })
            })

        case .restricted,
             .denied:
            // do nothing - access is not granted - camera will be not initialized
            break

        case .authorized:
            workQueue.async(execute: {
                self.setupCaptureSession(configuration: self.initialConfiguration)
            })
        }
    }

    private func videoAuthorizationStatusChanged(to newValue: AVAuthorizationStatus) {
        if authorizationForVideo != newValue {
            authorizationForVideo = newValue
            delegate?.videoCamera(self, authorizationStatusChanged: newValue)
        }
    }

}

// MARK: - AVCapturePhotoCaptureDelegate

extension DeviceCamera: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // settings are resolved, but they do not contain any interesting data
        workQueue.async(execute: {
            guard self.cameraDeviceInitializationStatus == .initialized,
                self.isCapturingPhoto,
                self.capturePhotoCompletionBlock != nil
                else {
                    return
            }
            self.delegate?.videoCameraWillCapturePhoto(self)
        })
    }

    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // we have only one callback - skipping
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // photo is captured, but not processed completely - skipping
    }

    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // photo is captured and processed - ready for consume
        // this is a callback for ios 11.0+
        workQueue.async(execute: {
            guard self.cameraDeviceInitializationStatus == .initialized,
                self.isCapturingPhoto,
                let completionBlock = self.capturePhotoCompletionBlock
                else {
                    return
            }
            if let actualError = error {
                completionBlock(nil, actualError)
            } else {
                if let imageData = photo.fileDataRepresentation() {
                    completionBlock(imageData, nil)
                } else {
                    completionBlock(nil, VideoCameraError.cantFlattenCapturedPhotoToData)
                }
            }
        })
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {
        // callback for iOS v10.0 - 10.9999999
        workQueue.async(execute: {
            guard self.cameraDeviceInitializationStatus == .initialized,
                self.isCapturingPhoto,
                let completionBlock = self.capturePhotoCompletionBlock
                else {
                    return
            }
            if let actualError = error {
                completionBlock(nil, actualError)
            } else {
                if let photoBuffer = photoSampleBuffer,
                    let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoBuffer,
                                                                                     previewPhotoSampleBuffer: previewPhotoSampleBuffer) {
                    completionBlock(imageData, nil)
                } else {
                    completionBlock(nil, VideoCameraError.cantFlattenCapturedPhotoToData)
                }
            }
        })
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingRawPhoto rawSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {
        // callback for iOS v10.0 - 10.9999999
        workQueue.async(execute: {
            guard self.cameraDeviceInitializationStatus == .initialized,
                self.isCapturingPhoto,
                let completionBlock = self.capturePhotoCompletionBlock
                else {
                    return
            }
            if let actualError = error {
                completionBlock(nil, actualError)
            } else {
                if let rawBuffer = rawSampleBuffer,
                    let imageData = AVCapturePhotoOutput.dngPhotoDataRepresentation(forRawSampleBuffer: rawBuffer,
                                                                                    previewPhotoSampleBuffer: previewPhotoSampleBuffer) {
                    completionBlock(imageData, nil)
                } else {
                    completionBlock(nil, VideoCameraError.cantFlattenCapturedPhotoToData)
                }
            }
        })
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        workQueue.async(execute: {
            guard self.cameraDeviceInitializationStatus == .initialized, self.isCapturingPhoto else {
                return
            }
            self.delegate?.videoCameraDidFinishRecordingLivePhoto(self, url: outputFileURL)
        })
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL,
                     duration: CMTime,
                     photoDisplayTime: CMTime,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {
        workQueue.async(execute: {
            guard self.cameraDeviceInitializationStatus == .initialized, self.isCapturingPhoto else {
                return
            }
            self.delegate?.videoCameraDidFinishProcessingLivePhoto(self, url: outputFileURL, duration: duration, photoDisplayTime: photoDisplayTime, error: error)
        })
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        // photo capture circle is complete. Clean-up state.
        workQueue.async(execute: {
            guard self.cameraDeviceInitializationStatus == .initialized,
                self.isCapturingPhoto,
                self.capturePhotoCompletionBlock != nil
                else {
                    return
            }
            self.isCapturingPhoto = false
            self.capturePhotoCompletionBlock = nil
            self.delegate?.videoCameraDidFinishCapturingPhoto(self, error: error)
        })
    }

}

// MARK: - Video Camera

extension DeviceCamera: VideoCamera {

    var isInitialized: Bool {
        return self.cameraDeviceInitializationStatus == .initialized
    }

    var cameraAuthrizationStatus: AVAuthorizationStatus {
        return VideoCameraFactory.authorizationStatusForVideo()
    }

    var previewView: UIView {
        return cameraPreviewView
    }

    var hasFlash: Bool {
        if self.cameraDeviceInitializationStatus == .initialized, let device = cameraDevice {
            return device.hasFlash
        } else {
            return false
        }
    }

    var flashMode: AVCaptureDevice.FlashMode {
        get {
            if hasFlash, let photoSettings = photoOutputSettings {
                return photoSettings.flashMode
            } else {
                return AVCaptureDevice.FlashMode.off
            }
        }
        set {
            workQueue.async(execute: {
                guard self.hasFlash,
                    let photoSettings = self.photoOutputSettings,
                    let output = self.photoOutput,
                    photoSettings.flashMode != newValue
                    else {
                        // do nothing
                        return
                }
                if output.supportedFlashModes.contains(newValue) {
                    self.photoOutputSettings?.flashMode = newValue
                    self.delegate?.videoCamera(self, flashModeForPhotoDidChanged: newValue)
                } else {
                    self.delegate?.videoCamera(self, error: VideoCameraError.flashModeUnsupported(requestedMode: newValue))
                }
            })
        }
    }

    func setNextFlashMode() {
        workQueue.async(execute: {
            guard self.hasFlash, let output = self.photoOutput, let photoSettings = self.photoOutputSettings else {
                // do nothing
                return
            }
            let modesCount = output.supportedFlashModes.count
            if modesCount > 1 {
                if let nextModeIndex = output.supportedFlashModes.index(of: photoSettings.flashMode) {
                    self.flashMode = output.supportedFlashModes[(nextModeIndex + 1) % modesCount]
                }
            }
        })
    }

    var hasTorch: Bool {
        if self.cameraDeviceInitializationStatus == .initialized, let device = cameraDevice {
            return device.hasTorch
        } else {
            return false
        }
    }

    var torchMode: AVCaptureDevice.TorchMode {
        get {
            if hasTorch, let device = cameraDevice {
                return device.torchMode
            } else {
                return AVCaptureDevice.TorchMode.off
            }
        }
        set {
            workQueue.async(execute: {
                guard self.hasTorch, let device = self.cameraDevice else {
                    // do nothing
                    return
                }
                if device.isTorchModeSupported(newValue) {
                    do {
                        try device.lockForConfiguration()
                        device.torchMode = newValue
                        // NOTE: change of torch mode property is observed by KVO
                        device.unlockForConfiguration()
                    } catch let error {
                        self.delegate?.videoCamera(self, error: VideoCameraError.cantLockCameraForConfiguration(underlyingError: error))
                    }
                } else {
                    self.delegate?.videoCamera(self, error: VideoCameraError.torchModeUnsupported(requestedMode: newValue))
                }
            })
        }
    }

    func selectNextTorchMode() {
        workQueue.async(execute: {
            guard self.hasTorch, let device = self.cameraDevice else {
                // do nothing
                return
            }
            let modes: [AVCaptureDevice.TorchMode] = [.on, .auto, .off]
            if let currentModeIndex = modes.index(of: device.torchMode) {
                for i in 1...2 {
                    let nextMode = modes[(currentModeIndex + i) % modes.count]
                    if device.isTorchModeSupported(nextMode) {
                        self.torchMode = nextMode
                        break
                    }
                }
            }
        })
    }

    func setDesiredFrameRate(_ frameRate: CMTimeScale) {
        workQueue.async(execute: {
            guard self.cameraDeviceInitializationStatus == .initialized, let device = self.cameraDevice else {
                return
            }
            do {
                try device.lockForConfiguration()
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: frameRate)
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: frameRate)
                device.unlockForConfiguration()
            } catch let error {
                self.delegate?.videoCamera(self, error: VideoCameraError.cantLockCameraForConfiguration(underlyingError: error))
            }
        })
    }

    var whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode {
        get {
            if self.cameraDeviceInitializationStatus == .initialized, let camera = cameraDevice {
                return camera.whiteBalanceMode
            } else {
                return AVCaptureDevice.WhiteBalanceMode.locked
            }
        }
        set {
            workQueue.async(execute: {
                guard self.cameraDeviceInitializationStatus == .initialized,
                    let device = self.cameraDevice,
                    device.whiteBalanceMode != newValue,
                    device.isWhiteBalanceModeSupported(newValue)
                    else {
                        return
                }
                do {
                    try device.lockForConfiguration()
                    device.whiteBalanceMode = newValue
                    device.unlockForConfiguration()
                } catch let error {
                    self.delegate?.videoCamera(self, error: VideoCameraError.cantLockCameraForConfiguration(underlyingError: error))
                }
            })
        }
    }

    var automaticallyEnablesLowLightBoostWhenAvailable: Bool {
        get {
            if self.cameraDeviceInitializationStatus == .initialized, let device = cameraDevice {
                return device.automaticallyEnablesLowLightBoostWhenAvailable
            } else {
                return false
            }
        }
        set {
            workQueue.async(execute: {
                guard self.cameraDeviceInitializationStatus == .initialized,
                    let device = self.cameraDevice,
                    device.isLowLightBoostSupported,
                    device.automaticallyEnablesLowLightBoostWhenAvailable != newValue
                    else {
                        return
                }
                do {
                    try device.lockForConfiguration()
                    device.automaticallyEnablesLowLightBoostWhenAvailable = newValue
                    device.unlockForConfiguration()
                } catch let error {
                    self.delegate?.videoCamera(self, error: VideoCameraError.cantLockCameraForConfiguration(underlyingError: error))
                }
            })
        }
    }

    var focusPointOfInterest: CGPoint {
        if self.cameraDeviceInitializationStatus == .initialized, let device = cameraDevice {
            return device.focusPointOfInterest
        } else {
            return CGPoint(x: 0.5, y: 0.5)
        }
    }

    func setFocusMode(_ mode: AVCaptureDevice.FocusMode, atPoint point: CGPoint) {
        workQueue.async(execute: {
            guard self.cameraDeviceInitializationStatus == .initialized,
                let device = self.cameraDevice,
                device.isFocusPointOfInterestSupported,
                device.isFocusModeSupported(mode)
                else {
                    return
            }
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = point
                device.focusMode = mode
                device.unlockForConfiguration()
            } catch let error {
                self.delegate?.videoCamera(self, error: VideoCameraError.cantLockCameraForConfiguration(underlyingError: error))
            }
        })
    }

    var smoothAutoFocusEnabled: Bool {
        get {
            if self.cameraDeviceInitializationStatus == .initialized, let device = cameraDevice {
                return device.isSmoothAutoFocusEnabled
            } else {
                return false
            }
        }
        set {
            workQueue.async(execute: {
                guard self.cameraDeviceInitializationStatus == .initialized,
                    let device = self.cameraDevice,
                    device.isSmoothAutoFocusSupported,
                    device.isSmoothAutoFocusEnabled != newValue
                    else {
                        return
                }
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = newValue
                    device.unlockForConfiguration()
                } catch let error {
                    self.delegate?.videoCamera(self, error: VideoCameraError.cantLockCameraForConfiguration(underlyingError: error))
                }
            })
        }
    }

    var autoFocusRangeRestriction: AVCaptureDevice.AutoFocusRangeRestriction {
        get {
            if self.cameraDeviceInitializationStatus == .initialized, let device = cameraDevice {
                return device.autoFocusRangeRestriction
            } else {
                return AVCaptureDevice.AutoFocusRangeRestriction.none
            }
        }
        set {
            workQueue.async(execute: {
                guard self.cameraDeviceInitializationStatus == .initialized,
                    let device = self.cameraDevice,
                    device.isAutoFocusRangeRestrictionSupported,
                    device.autoFocusRangeRestriction != newValue
                    else {
                        return
                }
                do {
                    try device.lockForConfiguration()
                    device.autoFocusRangeRestriction = newValue
                    device.unlockForConfiguration()
                } catch let error {
                    self.delegate?.videoCamera(self, error: VideoCameraError.cantLockCameraForConfiguration(underlyingError: error))
                }
            })
        }
    }

    var videoDataOutputSize: CGSize {
        guard self.cameraDeviceInitializationStatus == .initialized,
            let output = videoDataOutput
            else {
                return CGSize.zero
        }
        if let width = (output.videoSettings[kCVPixelBufferWidthKey as String]) as? NSNumber,
            let height = output.videoSettings[kCVPixelBufferHeightKey as String] as? NSNumber {
            return CGSize(width: width.doubleValue, height: height.doubleValue)
        } else {
            return CGSize.zero
        }
    }

    var videoDataOutputOrientation: AVCaptureVideoOrientation {
        guard self.cameraDeviceInitializationStatus == .initialized,
            let output = videoDataOutput,
            let connection = output.connection(with: AVMediaType.video)
            else {
                return AVCaptureVideoOrientation.portrait
        }
        return connection.videoOrientation
    }

    func startSession() {
        workQueue.async(execute: {
            switch self.cameraDeviceInitializationStatus {
            case .initializationError:
                return

            case .notInitialized:
                self.cameraShouldStartSessionAfterInitialization = true
                return

            case .waitingForAuthorization:
                self.cameraShouldStartSessionAfterInitialization = true
                self.authorizedSetup()

            case .initialized:
                if let session = self.captureSession, !session.isRunning {
                    DispatchQueue.main.async(execute: {
                        session.startRunning()
                    })
                }
            }
        })
    }

    func stopSession() {
        workQueue.async(execute: {
            switch self.cameraDeviceInitializationStatus {

            case .notInitialized,
                 .waitingForAuthorization:
                self.cameraShouldStartSessionAfterInitialization = false

            case .initialized:
                if let session = self.captureSession, session.isRunning {
                    DispatchQueue.main.async(execute: {
                        session.stopRunning()
                    })
                }

            case .initializationError:
                // do nothing
                break
            }
        })
    }

    func setVideoPreviewPaused(_ paused: Bool) {
        self.cameraPreviewView.setVideoPreviewPaused(paused)
    }

    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        internalCapturePhoto(delegate: delegate, completionBlock: nil)
    }

    func capturePhoto(completionBlock: @escaping (_ imageData: Data?, _ error: Error?) -> Void) {
        internalCapturePhoto(delegate: nil, completionBlock: completionBlock)
    }

    var metadataRectOfInterest: CGRect {
        get {
            if self.cameraDeviceInitializationStatus == .initialized, let output = metadataOutput {
                return cameraPreviewView.layerRectConverted(fromMetadataOutputRect: output.rectOfInterest)
            } else {
                return cameraPreviewView.bounds
            }
        }
        set {
            workQueue.async(execute: {
                guard self.cameraDeviceInitializationStatus == .initialized,
                    let output = self.metadataOutput
                    else {
                        return
                }
                DispatchQueue.main.async(execute: {
                    let rect = self.cameraPreviewView.metadataOutputRectConverted(fromLayerRect: newValue)
                    output.rectOfInterest = rect
                })
            })
        }
    }

    func transformedMetadataObject(_ metadataObject: AVMetadataObject) -> AVMetadataObject? {
        return cameraPreviewView.transformedMetadataObject(metadataObject)
    }

}

// MARK: - Private

extension DeviceCamera {

    private func getCamera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: position)
    }

    private func setCameraDevice(_ newCamera: AVCaptureDevice) {
        observationTokens.removeAll()
        cameraDevice = newCamera
        // torch mode
        if let token = cameraDevice?.observe(\AVCaptureDevice.torchMode, changeHandler: { [weak self] (device: AVCaptureDevice, _) in
            if let strongSelf = self {
                // "change" parameter of this block often contains nil values
                strongSelf.delegate?.videoCamera(strongSelf, torchModeDidChanged: device.torchMode)
            }
        }) {
            observationTokens.append(token)
        }
        // focus point of interest
        if let token = cameraDevice?.observe(\AVCaptureDevice.focusPointOfInterest, changeHandler: { [weak self] (device: AVCaptureDevice, _) in
            if let strongSelf = self {
                // "change" parameter of this block often contains nil values
                strongSelf.delegate?.videoCamera(strongSelf, focusPointOfInterestDidChanged: device.focusPointOfInterest)
            }
        }) {
            observationTokens.append(token)
        }
    }

    private func internalCapturePhoto(delegate: AVCapturePhotoCaptureDelegate?, completionBlock: ((_ imageData: Data?, _ error: Error?) -> Void)?) {
        workQueue.async(execute: {
            guard self.cameraDeviceInitializationStatus == .initialized,
                !self.isCapturingPhoto,
                let output = self.photoOutput,
                let connection = output.connection(with: AVMediaType.video),
                let settings = self.photoOutputSettings
                else {
                    return
            }
            if (delegate == nil) != (completionBlock == nil) { // this is just an internal sanity check
                self.isCapturingPhoto = true
                self.capturePhotoCompletionBlock = completionBlock
                connection.videoOrientation = self.orientationFromDevice()
                output.capturePhoto(with: AVCapturePhotoSettings(from: settings), delegate: delegate ?? self)
            } else {
                fatalError("DeviceCamera: can not use `capturePhoto` with delegate AND completion block")
            }
        })
    }

    private func orientationFromDevice() -> AVCaptureVideoOrientation {
        let orientation: UIDeviceOrientation
        if useDeviceOrientationListener, let listener = deviceOrientationListener {
            orientation = listener.currentOrientation
        } else {
            orientation = UIDevice.current.orientation
        }
        switch orientation {
        case .unknown,
             .faceDown,
             .faceUp:
            return AVCaptureVideoOrientation.portrait

        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeRight

        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeLeft

        case .portrait:
            return AVCaptureVideoOrientation.portrait

        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        }
    }

}
