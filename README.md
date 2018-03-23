![Shakuro iOS Toolbox](title_image.svg)

![Version](https://img.shields.io/badge/version-0.5.4-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![License MIT](https://img.shields.io/badge/license-MIT-green.svg)

Toolbox contains various components written in Swift.

- [Components List](#components-list)
- [Requirements](#requirements)
- [Installation](#installation)
- [License](#license)

## Components List

- [Device](/Device/)
    - **DeviceType** - Helper for detecting model of the device / simulator.
    - **DeviceOrientationListener** - Alternative for UIDevice.current.orientation.
- [Extensions](/Extensions/) - Various extensions with small helper functions.
- [ImageProcessing](/ImageProcessing/)
    - **ImageProcessor** - Helper for CGImage and UIImage
- [Keychain](/Keychain/)
    - **KeychainWrapper** - easy add/remove/get Codable object to/from Keychain.
- [Keyboard](/Keyboard/)
    - **KeyboardHandler** - wrapper around keyboard notifications
- [PlaceholderTextView](/PlaceholderTextView/) - UITextView subclass with a placeholder feature and ability to change own size depending on text contents
- [VideoCamera](/VideoCamera/) - wrapper for AVFoundation's camera.

## Requirements

- iOS 10.0+
- Xcode 9.2+
- Swift 4.0+

## Installation

### CocaPods

[CocaPods](http://cocapods.org) is a dependency manager for Coca projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate Toolbox into you Xcode project, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'Shakuro.iOS_Toolbox', :git => 'https://github.com/shakurocom/iOS_Toolbox', :tag => '0.5.4'
end
```

Then, run the following command:

```bash
$ pod install
```

You can use integrate only needed components. To do this you need to specify subpod:

```ruby
target '<Your Target Name>' do
    pod 'Shakuro.iOS_Toolbox/<Component Name>', :git => 'https://github.com/shakurocom/iOS_Toolbox', :tag => '0.5.4'
#example:
    pod 'Shakuro.iOS_Toolbox/Keychain', :git => 'https://github.com/shakurocom/iOS_Toolbox', :tag => '0.5.4'
end
```

### Manually

If you prefer to not use CocoPods, than you can integrate any/all components from Shakuro iOS Toolbox simply by copying them to your project

## License

Shakuro iOS Toolbox is released under the MIT license. [See LICENSE](https://github.com/shakurocom/iOS_Toolbox/blob/master/LICENSE) for details.
