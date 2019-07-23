![Shakuro iOS Toolbox](title_image.svg)
<br><br>

![Version](https://img.shields.io/badge/version-0.17.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![License MIT](https://img.shields.io/badge/license-MIT-green.svg)

Toolbox contains various components written in Swift.

- [Component List](#component-list)
- [Requirements](#requirements)
- [Installation](#installation)
- [License](#license)

## Component List

- [Device](/Device/)
    - **DeviceType** - A helper for detecting model of the device/simulator.
    - **DeviceOrientationListener** - The alternative for `UIDevice.current.orientation`.
- [Extensions](/Extensions/) - Various extensions with small helper functions.
- [ImageProcessing](/ImageProcessing/)
    - **ImageProcessor** - A helper for `CGImage` and `UIImage`.
- [Keychain](/Keychain/)
    - **KeychainWrapper** - A wrapper to easily add, remove, or get `Codable` object to/from Keychain.
- [Keyboard](/Keyboard/)
    - **KeyboardHandler** - A wrapper around keyboard notifications.
- [PlaceholderTextView](/PlaceholderTextView/) - A `UITextView` subclass with a placeholder feature and the ability to change own size depending on the text contents.
- [VideoCamera](/VideoCamera/) - A wrapper for AVFoundation camera.

## Requirements

- iOS 10.0+
- Xcode 9.2+
- Swift 4.0+

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate Toolbox into your Xcode project, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'Shakuro.iOS_Toolbox', :git => 'https://github.com/shakurocom/iOS_Toolbox', :tag => '0.17.0'
end
```

Then, run the following command:

```bash
$ pod install
```

You can use/integrate only the necessary components. To do this, you need to specify the subpod:

```ruby
target '<Your Target Name>' do
    pod 'Shakuro.iOS_Toolbox/<Component Name>', :git => 'https://github.com/shakurocom/iOS_Toolbox', :tag => '0.17.0'
#example:
    pod 'Shakuro.iOS_Toolbox/Keychain', :git => 'https://github.com/shakurocom/iOS_Toolbox', :tag => '0.17.0'
end
```

### Manually

If you prefer not to use CocoaPods, you can integrate any/all components from the Shakuro iOS Toolbox simply by copying them to your project.

## License

Shakuro iOS Toolbox is released under the MIT license. [See LICENSE](https://github.com/shakurocom/iOS_Toolbox/blob/master/LICENSE) for details.
