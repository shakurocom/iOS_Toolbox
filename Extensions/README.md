# Shakuro iOS Toolbox / Extensions

## String+Hash

Helper functions to get `MD5` and `SHA512` hash from string.

```swift
let stringValue = "foo bar"
let hashValue = stringValue.MD5()
```

## UIApplication

Helper function to obtain current app's bundle identifier.

## UIStoryboard

Helper function to instantiate a `UIViewController`, cast it to given type and unwrap result. If controller with provided ID not found inside storyboard, or if it has different type - `fatalError()` will be called.
