# Shakuro iOS Toolbox / VideoCamera

Wrapper around AVFoundation's camera. Works with several data outputs, such as metadata, video data, still image capture.

## Usage

Each `VideoCamera` must be provided with `VideoCameraConfiguration` structure. Go though it's extensive array of settings. For a simple setup of back-facing camera, that provides only video data preview without ability to get still images:

```swift
private var camera: VideoCamera?

override func viewDidLoad() {
    super.viewDidLoad()
    
    // ...
    
    var cameraConfig = VideoCameraConfiguration()
    cameraConfig.cameraDelegate = self
    cameraConfig.captureSessionPreset = .high
    cameraConfig.capturePhotoEnabled = false
    cameraConfig.videoFeedDelegate = self
    cameraConfig.simulatedImage = UIImage(named: "card_backside.png")?.cgImage
    let videoCamera = VideoCameraFactory.createCamera(configuration: cameraConfig)
    camera = videoCamera
    
    // ...
}
```

To display camera preview, one of the simplest ways is to prepare container view in storyboard a than add camera's preview to it:

```swift
@IBOutlet private var cameraPreviewContainerView: UIView!

override func viewDidLoad() {
    super.viewDidLoad()
    
    // setup camera (see above)

    let preview = videoCamera.previewView
    preview.translatesAutoresizingMaskIntoConstraints = true
    preview.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
    preview.frame = cameraPreviewContainerView.bounds
    cameraPreviewContainerView.insertSubview(preview, at: 0)
    
    // ...
}
```

Changes of camera's properties are observed via delegate:

```swift
extension MyViewController: VideoCameraDelegate {

    func videoCamera(_ videoCamera: VideoCamera, error: Error) {
        // display/process error
    }

    func videoCameraInitialized(_ videoCamera: VideoCamera, errors: [VideoCameraError]) {
        // update UI - such as flash button (with actual state of camera)
    }

    func videoCamera(_ videoCamera: VideoCamera, flashModeForPhotoDidChanged newValue: AVCaptureDevice.FlashMode) {
        // update flash button
    }
    
    // ... other delegate functions
    
}
```
