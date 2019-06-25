//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import CoreGraphics

public extension CGSize {

    func aspectFitedToSize(_ maxSize: CGSize, denyUpscale: Bool) -> CGSize {
        let scaleW = maxSize.width / self.width
        let scaleH = maxSize.height / self.height
        var scale = CGFloat.minimum(scaleW, scaleH)
        if denyUpscale {
            scale = CGFloat.minimum(scale, 1.0)
        }
        return CGSize(width: self.width * scale, height: self.height * scale)
    }

}
