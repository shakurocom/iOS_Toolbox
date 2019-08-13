//
//  Copyright © 2019 Shakuro. All rights reserved.
//

import UIKit

extension UIColor {

    static func randomColor(colorRange: ClosedRange<CGFloat>? = nil,
                            alphaRange: ClosedRange<CGFloat>? = nil) -> UIColor {
        let range: ClosedRange<CGFloat> = colorRange ?? 0...1
        let alpha: CGFloat
        if let actualAlphaRange = alphaRange {
            alpha = CGFloat.random(in: actualAlphaRange)
        } else {
            alpha = 1.0
        }
        return UIColor(red: CGFloat.random(in: range),
                       green: CGFloat.random(in: range),
                       blue: CGFloat.random(in: range),
                       alpha: alpha)
    }

    static func randomColor(colorRange: ClosedRange<Int>? = nil,
                            alphaRange: ClosedRange<CGFloat>? = nil) -> UIColor {
        let range: ClosedRange<Int> = colorRange ?? 0...255
        let alpha: CGFloat
        if let actualAlphaRange = alphaRange {
            alpha = CGFloat.random(in: actualAlphaRange)
        } else {
            alpha = 1.0
        }
        return UIColor(red: CGFloat(Int.random(in: range))/255.0,
                       green: CGFloat(Int.random(in: range))/255.0,
                       blue: CGFloat(Int.random(in: range))/255.0,
                       alpha: alpha)
    }

    convenience init(decimalColor: UInt32) {
        let mask = 0x000000FF
        let rComponent: Int = Int(decimalColor >> 16) & mask
        let gComponent: Int = Int(decimalColor >> 8) & mask
        let bComponent: Int = Int(decimalColor) & mask

        let red: CGFloat = CGFloat(rComponent) / 255.0
        let green: CGFloat = CGFloat(gComponent) / 255.0
        let blue: CGFloat  = CGFloat(bComponent) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    convenience init(hex: String) {
        let validateHex: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner: Scanner = Scanner(string: validateHex)

        if validateHex.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        self.init(decimalColor: color)
    }

    func generateImage(destinationSize: CGSize = CGSize(width: 1.0, height: 1.0),
                       scale: CGFloat = 0,
                       opaque: Bool = false) -> UIImage? {
        guard !destinationSize.equalTo(CGSize.zero) else {
            return nil
        }
        defer {
            UIGraphicsEndImageContext()
        }
        let drawRect = CGRect(origin: CGPoint(x: 0, y: 0), size: destinationSize)
        UIGraphicsBeginImageContextWithOptions(drawRect.size, opaque, scale)
        guard let currentContext = UIGraphicsGetCurrentContext() else {
            return nil
        }
        currentContext.setFillColor(cgColor)
        currentContext.fill(drawRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
