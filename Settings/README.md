# Settings

Wrapper for UserDefaults.

## Requirements
* iOS 10.0+
* Xcode 9.2+
* Swift 4.0+

## Installation
### CocoaPods
[CocoaPods](https://cocoapods.org/) is a dependency manager for Cocoa projects. You can install it with the following command:

```
$ gem install cocoapods
```

To integrate Settings into your Xcode project, specify it in your Podfile:

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'Shakuro.iOS_Toolbox/Settings'
end
```

Then, run the following command:

```
$ pod install
```

### Manually
If you prefer not to use CocoaPods, you can integrate Settings simply by copying them to your project.

## Usage

Subclass from Settings and add SettingItem<Type> vars to it.

```swift
class MySettings: Settings {
     let boolProperty = SettingItemNumber<Bool>(key: "boolProperty", defaultValue: false)
}
```
Inside your `UIViewController`:
```swift
class ViewController: UIViewController {
    @IBOutlet private var boolValueSwitch: UISwitch!

    private let settings: MySettings = MySettings()
    private var notificationToken: EventHandlerToken?
    
    deinit {
        if let token = notificationToken {
            settings.boolProperty.didChange.removeHandler(token: token)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        boolValueSwitch.isOn = settings.boolProperty.value
        notificationToken = settings.boolProperty.didChange.add(handler: { (change) in
            print("my setting 'boolProperty' changed from '\(change.oldValue)' to '\(change.newValue)'")
        })
    }
    
    @IBAction private func boolValueSwitchValueChanged() {
        settings.boolProperty.setValue(boolValueSwitch.isOn)
    }
}
```

## License
Settings is released under the MIT license. [See LICENSE](https://github.com/shakurocom/iOS_Toolbox/blob/master/LICENSE) for details.
