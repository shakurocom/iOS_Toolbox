//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import AVFoundation

public class VideoCameraFactory {

    private init() {}

    /**
     Designated constructor.

     - Parameter simulatedImage: used, when running on simulator. **Required on simulator**. Will be displayed in preview view and returned as a taken photo.
     */
    public static func createCamera(configuration: VideoCameraConfiguration) -> VideoCamera {
        let camera: VideoCamera
        if DeviceType.current == .simulator {
            do {
                camera = try SimulatorCamera(configuration: configuration)
            } catch let error as VideoCameraError {
                fatalError("VideoCamera: " + error.errorDescription())
            } catch let error {
                fatalError("VideoCamera: " + error.localizedDescription)
            }
        } else {
            camera = DeviceCamera(configuration: configuration)
        }
        return camera
    }

    public static func authorizationStatusForVideo() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    }

    public static func authorizationStatusForAudio() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
    }

    public static func requestAuthorizationForVideo(completion: @escaping (_ authGranted: Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (authGranted: Bool) -> Void in
            completion(authGranted)
        })
    }

    public static func requestAuthorizationForAudio(completion: @escaping (_ authGranted: Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { (authGranted: Bool) -> Void in
            completion(authGranted)
        })
    }

}
