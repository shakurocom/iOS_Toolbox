//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

/**
 UILabel with 'contentInsets' functionality.
 */
public class InsetsLabel: UILabel {

    // MARK: - Public

    /**
     Corner radius.
     If greater than zero, than a background rounded rect will be drawn under the text.
     Color is 'roundedBackgroundColor'.
     Default value is 0.
     */
    public var cornerRadius: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    /**
     Color of the rounded rect, that is drawn under the text.
     Default value is `UIColor.clear`.
     */
    public var roundedBackgroundColor: UIColor = UIColor.clear {
        didSet {
            setNeedsDisplay()
        }
    }

    /**
     Insets between `bounds` and text.
     Default value is UIEdgeInsets.zero
     */
    public var contentInsets: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }

    // MARK: - Overrides

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        var superSize: CGSize = super.sizeThatFits(size)
        superSize.width += contentInsets.left + contentInsets.right
        superSize.height += contentInsets.top + contentInsets.bottom
        return superSize
    }

    override public var intrinsicContentSize: CGSize {
        var superSize: CGSize = super.intrinsicContentSize
        superSize.width += contentInsets.left + contentInsets.right
        superSize.height += contentInsets.top + contentInsets.bottom
        return superSize
    }

    override public func draw(_ rect: CGRect) {
        if cornerRadius > 0, let currentContext = UIGraphicsGetCurrentContext() {
            currentContext.setFillColor(roundedBackgroundColor.cgColor)
            let markPath: UIBezierPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
            markPath.fill()
        }
        super.draw(rect)
    }

    override public func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

}
