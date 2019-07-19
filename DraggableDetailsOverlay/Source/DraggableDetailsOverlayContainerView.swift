//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import UIKit

internal class DraggableDetailsOverlayContainerView: UIView {

    internal var isRoundedTopCornersEnabled: Bool = false {
        didSet {
            if isRoundedTopCornersEnabled {
                layer.mask = maskLayer
                updateMaskPath(forced: true)
            } else {
                maskSize = .zero
                layer.mask = nil
            }
        }
    }

    internal var topCornersRadius: CGFloat = 5 {
        didSet {
            updateMaskPath(forced: true)
        }
    }

    private var maskLayer: CAShapeLayer = CAShapeLayer()
    private var maskSize: CGSize = .zero

    internal override init(frame: CGRect) {
        super.init(frame: frame)
        layer.mask = isRoundedTopCornersEnabled ? maskLayer : nil
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.mask = isRoundedTopCornersEnabled ? maskLayer : nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateMaskPath(forced: false)
    }

    private func updateMaskPath(forced: Bool) {
        guard layer.mask != nil && (maskSize != bounds.size || forced) else {
            return
        }
        let path = UIBezierPath(roundedRect: bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: topCornersRadius, height: topCornersRadius))
        maskLayer.path = path.cgPath
    }

}
