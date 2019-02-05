//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Vlad Onipchenko
//

import UIKit

/**
 UITextView subclass with an additional functionality.

 Main features are placeholder text and ability to change self's size according to text.
 */
public class PlaceholderTextView: UITextView {

    /// Callback for 'text did changed' event
    public var textDidChange: ((_ text: String?) -> Void)?

    /// Container view that will be requested to update its layout when text/bounds is changed
    public weak var layoutContainerView: UIView?

    /// if **true** - change of self's size will be animated
    public var animateIntrinsicContentSize: Bool = false

    /// Duration of "change size" animation
    public var intrinsicContentSizeAnimationDuration: TimeInterval = 0.2

    /// Should be set to **true** if you whant "hagging text" functionality
    public var contentSizeBased: Bool = false

    public var maxLength: Int = 0 {
        didSet {
            updateTextWithLimit()
        }
    }

    public var counterLabel: UILabel?

    public var counterLabelFont: UIFont? = nil {
        didSet {
            counterLabel?.font = counterLabelFont
        }
    }

    public var counterLabelTextColor: UIColor? = nil {
        didSet {
            counterLabel?.textColor = counterLabelTextColor
        }
    }

    public var placeholder: String? {
        set {
            placeholderTextView.text = newValue
            invalidateIntrinsicContentSize()
            updatePlaceholder()
        }
        get {
            return placeholderTextView.text
        }
    }

    public var attributedPlaceholder: NSAttributedString? {
        set {
            placeholderTextView.attributedText = newValue
            invalidateIntrinsicContentSize()
            updatePlaceholder()
        }
        get {
            return placeholderTextView.attributedText
        }
    }

    public var placeholderTextColor: UIColor? {
        set {
            placeholderTextView.textColor = newValue
        }
        get {
            return placeholderTextView.textColor
        }
    }

    // MARK: - Overrides

    override public var text: String! {
        didSet {
            updatePlaceholder()
        }
    }

    override public var attributedText: NSAttributedString! {
        didSet {
            updatePlaceholder()
        }
    }

    override public var font: UIFont? {
        didSet {
            placeholderTextView.font = font
        }
    }

    override public var textAlignment: NSTextAlignment {
        didSet {
            placeholderTextView.textAlignment = textAlignment
            invalidateIntrinsicContentSize()
        }
    }

    override public var textContainerInset: UIEdgeInsets {
        didSet {
            placeholderTextView.textContainerInset = textContainerInset
            invalidateIntrinsicContentSize()
        }
    }

    override public var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        let contentHeight: CGFloat
        if contentSizeBased {
            contentHeight = contentSize.height + contentInset.top + contentInset.bottom
        } else {
            contentHeight = size.height
        }
        let resultSize: CGSize
        if !placeholderTextView.isEmpty() {
            let placeHolderSize = placeholderTextView.intrinsicContentSize
            resultSize = CGSize(width: size.width, height: max(placeHolderSize.height, contentHeight))
        } else {
            resultSize = CGSize(width: size.width, height: contentHeight)
        }
        return resultSize
    }

    override public var contentSize: CGSize {
        didSet {
            updateCounterLabelPosition()
        }
    }

    override public var bounds: CGRect {
        didSet {
            updateCounterLabelPosition()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
    }

    override public func becomeFirstResponder() -> Bool {
        let result: Bool = super.becomeFirstResponder()
        updateCounterLabel()
        return result
    }

    override public func resignFirstResponder() -> Bool {
        let result: Bool = super.resignFirstResponder()
        updateCounterLabel()
        return result
    }

    // MARK: - Public

    public func updatePlaceholderTextContainer() {
        updatePlaceholderTextContainer(placeholderTextView)
        invalidateIntrinsicContentSize()
    }

    // MARK: - Init

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.commonInit()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: self)
    }

    // MARK: - Private

    private func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(PlaceholderTextView.textViewTextDidChange(_:)), name: UITextView.textDidChangeNotification, object: self)
    }

    private lazy var placeholderTextView: UITextView = { [weak self] in
        let placeholder = UITextView()
        placeholder.isOpaque = false
        placeholder.backgroundColor = UIColor.clear
        placeholder.textColor = UIColor(white: 0.7, alpha: 0.7)
        placeholder.textAlignment = self?.textAlignment ?? .center
        placeholder.isEditable = false
        placeholder.isScrollEnabled = false
        placeholder.isUserInteractionEnabled = false
        placeholder.font = self?.font
        placeholder.isAccessibilityElement = false
        placeholder.contentOffset = self?.contentOffset ?? CGPoint(x: 0, y: 0)
        placeholder.contentInset = self?.contentInset ?? UIEdgeInsets.zero
        placeholder.isSelectable = false
        placeholder.alpha = 0.0
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        self?.updatePlaceholderTextContainer(placeholder)
        return placeholder
        }()

}

private extension PlaceholderTextView {

    @objc func textViewTextDidChange(_ notification: Notification) {
        if animateIntrinsicContentSize && superview != nil && window != nil {
            self.superview?.setNeedsLayout()
            self.layoutContainerView?.setNeedsLayout()
            self.setNeedsLayout()
            UIView.animate(withDuration: intrinsicContentSizeAnimationDuration, animations: { () -> Void in
                self.invalidateIntrinsicContentSize()
                self.layoutIfNeeded()
                if let actualContainer: UIView = self.layoutContainerView {
                    actualContainer.layoutIfNeeded()
                } else {
                    self.superview?.layoutIfNeeded()
                }
            })
        }
        updatePlaceholder()
        updateTextWithLimit()
        textDidChange?(text)
    }

    func updatePlaceholder() {
        if isEmpty() && !placeholderTextView.isEmpty() {
            addPlaceholderView()
            placeholderTextView.alpha = 1.0
        } else {
            placeholderTextView.alpha = 0.0
            placeholderTextView.removeFromSuperview()
        }
    }

    func addPlaceholderView() {
        if placeholderTextView.superview == nil {
            placeholderTextView.alpha = 0.0
            addSubview(placeholderTextView)
            let width = NSLayoutConstraint(item: placeholderTextView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0)
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[placeholder]|", options: [], metrics: nil, views: ["placeholder": placeholderTextView]))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[placeholder]", options: [], metrics: nil, views: ["placeholder": placeholderTextView]))
            addConstraint(width)
            sendSubviewToBack(placeholderTextView)
        }
    }

    func updatePlaceholderTextContainer(_ view: UITextView) {
        view.textContainer.exclusionPaths = self.textContainer.exclusionPaths
        view.textContainer.lineFragmentPadding = self.textContainer.lineFragmentPadding
    }

    func updateTextWithLimit() {
        if maxLength > 0, let currentText: String = text {
            let currentCount: Int = currentText.count
            if currentCount > maxLength {
                text = currentText.padding(toLength: maxLength, withPad: "", startingAt: 0)
            }
        }
        updateCounterLabel()
    }

    func createCounterLabelIfNeeded() -> UILabel {
        if let actualCounterLabel: UILabel = counterLabel {
            return actualCounterLabel
        } else {
            let label: UILabel = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = true
            label.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
            label.font = counterLabelFont
            label.textColor = counterLabelTextColor
            label.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            label.textAlignment = .center
            label.layer.masksToBounds = true
            label.layer.cornerRadius = 4.0
            counterLabel = label
            updateCounterLabelPosition()
            addSubview(label)
            return label
        }
    }

    func updateCounterLabelPosition() {
        if isFirstResponder, let label: UILabel = counterLabel, label.superview === self {
            label.sizeToFit()
            let padding: CGFloat = 5.0
            var currentFrame: CGRect = label.frame
            currentFrame.size.width += padding * 0.5
            let originY: CGFloat = bounds.size.height - currentFrame.size.height - padding
            let originX: CGFloat = bounds.size.width - currentFrame.size.width - padding * 2.0
            currentFrame.origin.x = originX
            currentFrame.origin.y = contentOffset.y + originY
            if !label.frame.equalTo(currentFrame) {
                label.frame = currentFrame
            }
            let inset: CGFloat = (currentFrame.size.height + padding)
            if contentInset.bottom != inset {
                UIView.animate(withDuration: 0.2, animations: {
                    var currentInset: UIEdgeInsets = self.contentInset
                    currentInset.bottom = inset
                    self.contentInset = currentInset
                })
            }
        }
    }

    func updateCounterLabel() {
        if isFirstResponder && maxLength > 0 {
            let label: UILabel = createCounterLabelIfNeeded()
            let currentCount: Int = text?.count ?? 0
            label.text = "\(currentCount)/\(maxLength)"
            if label.superview === self {
                updateCounterLabelPosition()
            }
        } else {
            if let label: UILabel = counterLabel, label.superview === self {
                UIView.animate(withDuration: 0.2, animations: {
                    label.layer.removeAllAnimations()
                    label.removeFromSuperview()
                    self.counterLabel = nil
                    if self.contentInset.bottom != 0 {
                        var currentInset: UIEdgeInsets = self.contentInset
                        currentInset.bottom = 0
                        self.contentInset = currentInset
                        self.setContentOffset(CGPoint.zero, animated: false)
                    }
                })
            }
        }
    }

}

private extension UITextView {

    func isEmpty() -> Bool {
        let textEmpty = text?.isEmpty ?? true
        let attrTextEmpty = attributedText?.string.isEmpty ?? true
        return textEmpty && attrTextEmpty
    }
}
