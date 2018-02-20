# Shakuro iOS Toolbox / PlaceholderTextView

UITextView subclass with a placeholder feature and ability to change own size depending on text contents. 

## Usage

Add `UITextView` control in storyboard to your scene (controller) and change it's class to `PlaceholderTextView`.
By default `PlaceholderTextView` will behave exactly as `UITextView`.

```swift
@IBOutlet private var textView: PlaceholderTextView!
```

You need to enable additional features in code.

Placeholder label:

```swift
textView.placeholder = NSLocalizedString("Placeholder text", comment: "")
```

Contents hagging:

```swift
textView.layoutContainerView = textViewContinerView
textView.animateIntrinsicContentSize = true
textView.contentSizeBased = true
```

If you set `maxLength` property to non-zero value, than characters counter label will be displayed in lower-right corner:

```swift
textView.maxLength = 144
```
