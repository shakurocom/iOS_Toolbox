# Shakuro iOS Toolbox / ImageProcessing

## ImageProcessor

A helper for working with `CGImage` and `UIImage`.

### Usage

There is only one function at the moment - for creating `CVPixelBuffer` from `CGImage`:

```swift
let uiImage = UIImage(named: "some-image.png")
let buffer = ImageProcessor.createBGRAPixelBuffer(image: uiImage.cgimage)
```
