//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation

public protocol PredicateConvertible {
    func getPredicateFormat() -> String
    func getPredicateValue() -> CVarArg
}

extension Int64: PredicateConvertible {
    public func getPredicateFormat() -> String {
        return "%lld"
    }
    public func getPredicateValue() -> CVarArg {
        return self
    }
}

extension String: PredicateConvertible {
    public func getPredicateFormat() -> String {
        return "%@"
    }
    public func getPredicateValue() -> CVarArg {
        return self
    }
}
