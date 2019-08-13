//
//  Copyright © 2019 Shakuro. All rights reserved.
//

import Foundation

public final class ShortNumberFormatter {

    private enum Constant {
        static let suffixes: [String] = [ "", "k", "M", "G", "T", "P", "E" ]
        static let step: Double = 1000
        static let digitsInStep: Int = 3
    }

    let numberFormatter: NumberFormatter

    init(numberFormatter: NumberFormatter? = nil) {
        if let actualFormatter = numberFormatter {
            self.numberFormatter = actualFormatter
        } else {
            let formatter: NumberFormatter = NumberFormatter()
            formatter.locale = Locale.current
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            formatter.roundingMode = .down
            self.numberFormatter = formatter
        }
    }

    func string(for doubleValue: Double) -> String {
        let value: Double = abs(doubleValue)
        let suffixes = Constant.suffixes
        let suffixIndex: Int
        let shortValue: Double
        if value < Constant.step {
            suffixIndex = 0
            shortValue = value
        } else {
            let digitCount: Double = log10(value)
            if digitCount.isFinite {
                let maxIndex = suffixes.count - 1
                let maxDigitCount = Double(Constant.digitsInStep * maxIndex)
                suffixIndex = digitCount < maxDigitCount ? Int(digitCount / Double(Constant.digitsInStep)) : maxIndex
                shortValue = value/pow(Constant.step, Double(suffixIndex))
            } else {
                // fallback to original value without prefix
                assertionFailure("\(type(of: self)) - \(#function): . log10(value) produced NaN or infinity")
                suffixIndex = 0
                shortValue = value
            }
        }
        let resultValue = doubleValue < 0 ? -shortValue : shortValue
        let suffix = suffixes[suffixIndex]
        if let shortString: String = numberFormatter.string(for: resultValue) {
            return "\(shortString)\(suffix)"
        } else {
            // fallback to string interpolation
            assertionFailure("\(type(of: self)) - \(#function): . numberFormatter returned nil result")
            return "\(resultValue)\(suffix)"
        }
    }
}
