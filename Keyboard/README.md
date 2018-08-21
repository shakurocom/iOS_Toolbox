# Shakuro iOS Toolbox / Keyboard

A wrapper around keyboard notifications.

## Usage

Add a strong reference inside your `UIViewController`:

```swift
private var keyboardHandler: KeyboardHandler!
```

Initialize it inside `viewDidLoad()`:

```swift
keyboardHandler = KeyboardHandler(heightDidChange: { [weak self] (newKeyboardHeight: CGFloat, animationDuration: TimeInterval) in
    if let strongSelf = self {
        // animate UI
    }
})
```

It is better to enable and disable it when your controller is appearing and disappering:

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    keyboardHandler.isActive = true
}

override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    keyboardHandler.isActive = false
}
```

## iPhone X

On **iPhone X** exists new feature to quickly switch between apps. Quick change between two apps one of which has open keyboard leads to several notifications generated with wrong data. At the moment there is no way to detect these "bad" notifications. So, it is strongly advised to add additional check before you do your animations:

```swift
// inside KeyboardHandler's block
if let strongSelf = self {
    if strongSelf.controlWithKeyboardIsEditing() || newKeyboardHeight == 0 {
        // animate UI
    }
}



// somewhere in your UIViewController
private func controlWithKeyboardIsEditing() -> Bool {
    return someTextField.isEditing   // or some other expression, that suits your needs
}
```
