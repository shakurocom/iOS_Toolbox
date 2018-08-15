# Shakuro iOS Toolbox / Device

## DeviceType

A helper for detecting model of the device/simulator.

### Usage

Pretty stright forward:

```swift
if DeviceType.current == .simulator {
    // this is a simulator - do simulator stuff
}
```

## DeviceOrientationListener

Utility object to use instead of `UIDevice.current.orientation`. Gives much better results, but uses CoreMotion.

### Usage

It is advised to release or disable listener when it is not needed to save some resources:

```swift
let deviceOrientationListener = DeviceOrientationListener()
deviceOrientationListener.beginListeningDeviceOrientation()

// ...
if deviceOrientationListener.currentOrientation == UIDeviceOrientation.portrait {
    print("device is in portraint orientation")
}
// ...

deviceOrientationListener.endListeningDeviceOrientation()
```
