//
//
//

import Foundation
import UIKit

internal enum MyEnum: Int, Codable, RawCodable {
    case sample1
    case sample2
}

internal enum MyEnum2: Int, Codable {  // this type will be encoded as JSON Data
    case sample1
    case sample2
}

internal class MySettings: Settings {
    internal let settingItemBoolDefaultFalse = SettingItem<Bool>(key: "shakuro.iOSToolboxExample.MySettings.Bool", defaultValue: false)
    internal let settingItemEnum = SettingItem<MyEnum>(key: "shakuro.iOSToolboxExample.MySettings.MyEnum", defaultValue: .sample1)
    internal let settingItemIntOptional = SettingItem<Int?>(key: "shakuro.iOSToolboxExample.MySettings.IntOptional", defaultValue: nil)
    //internal let settingItemEnumOptional = SettingItem<MyEnum?>(key: "shakuro.iOSToolboxExample.MySettings.IntOptional", defaultValue: .sample1) // this will give fatalError
    internal let settingItemEnum2Optional = SettingItem<MyEnum2?>(key: "shakuro.iOSToolboxExample.MySettings.IntOptional", defaultValue: nil)
}

internal class ExampleSettingsViewController: UIViewController {

    @IBOutlet private var boolValueSwitch: UISwitch!

    private var example: Example?
    private let settings: MySettings = MySettings()
    private var notificationToken: EventHandlerToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title
        boolValueSwitch.isOn = settings.settingItemBoolDefaultFalse.value
        notificationToken = settings.settingItemBoolDefaultFalse.didChange.add(handler: { (change) in
            print("my setting 'settingItemBoolDefaultFalse' changed from '\(change.oldValue)' to '\(change.newValue)'")
        })
    }

    deinit {
        if let token = notificationToken {
            settings.settingItemBoolDefaultFalse.didChange.removeHandler(token: token)
        }
    }

    @IBAction private func boolValueSwitchValueChanged() {
        settings.settingItemBoolDefaultFalse.value = true
        settings.settingItemEnum.value = .sample2
        settings.settingItemIntOptional.value = nil
        settings.settingItemEnum2Optional.value = nil
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExampleSettingsViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleSettingsViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleSettingsViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
