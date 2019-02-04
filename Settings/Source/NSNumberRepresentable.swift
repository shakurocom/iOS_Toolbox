//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

/**
 Protocol to make NSNumber into a generic class for all ints and floats.
 */
public protocol NSNumberRepresentable {
    init?(nsnumber: NSNumber?)
    func nsnumber() -> NSNumber?
}

extension Optional: NSNumberRepresentable where Wrapped: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber, let wrapped = Wrapped(nsnumber: realNumber) {
            self = .some(wrapped)
        } else {
            self = .none
        }
    }

    public func nsnumber() -> NSNumber? {
        switch self {
        case .none:
            return nil
        case .some(let wrapped):
            return wrapped.nsnumber()
        }
    }

}

extension Int: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.intValue
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension Int8: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.int8Value
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension Int16: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.int16Value
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension Int32: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.int32Value
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension Int64: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.int64Value
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension UInt: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.uintValue
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension UInt8: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.uint8Value
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension UInt16: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.uint16Value
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension UInt32: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.uint32Value
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension UInt64: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.uint64Value
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension Float: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.floatValue
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension Double: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.doubleValue
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}

extension Bool: NSNumberRepresentable {

    public init?(nsnumber: NSNumber?) {
        if let realNumber = nsnumber {
            self = realNumber.boolValue
        } else {
            return nil
        }
    }

    public func nsnumber() -> NSNumber? {
        return NSNumber(value: self)
    }

}
