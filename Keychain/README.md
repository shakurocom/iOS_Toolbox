# Shakuro iOS Toolbox / Keychain

An easy to use wrapper for adding, removing and reading `Codable` objects to/from Keychain.

## Usage

Import module:

```swift
import Shakuro_iOS_Toolbox
```

KeychainWrapper works with `Codable` objects:

```swift
struct UserCredentials: Codable {
    let username: String
    let password: String
}

enum Constant {
    static let keychainServiceName: String = "com.shakuro.testApp"
    static let keychainItemId: String = "testUserCredentials"
}
```

Save data into Keychain:

```swift
func saveItemToKeychain() {
    let credentials = UserCredentials(username: "myUsername", password: "myPassword")
    let item = KeychainWrapper.Item(
        serviceName: Constant.keychainServiceName,
        itemId: Constant.keychainItemId,
        itemName: nil,
        secValue: credentials)
    KeychainWrapper.saveKeychainItem(item)
}
```

Read item from Keychain:

```swift
func readItemFromKeychain() {
    let keychainItem: KeychainWrapper.Item<UserCredentials>? = KeychainWrapper.keychainItem(
        itemId: Constant.keychainItemId, 
        serviceName: Constant.keychainServiceName)
    if let userCredentials = keychainItem?.secValue {
        print("username: \(userCredentials.username)")
        print("password: \(userCredentials.password)")
    }
}
```

Remove item from Keychain:

```swift
func removeItemFromKeychain() {
    KeychainWrapper.removeKeychainItem(
        itemId: Constant.keychainItemId,
        serviceName: Constant.keychainServiceName)
}
```
