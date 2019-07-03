//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation

protocol PredicateConvertible {
    func getPredicateFormat() -> String
    func getPredicateValue() -> CVarArg
}

extension Int64: PredicateConvertible {
    func getPredicateFormat() -> String {
        return "%lld"
    }
    func getPredicateValue() -> CVarArg {
        return self
    }
}

extension String: PredicateConvertible {
    func getPredicateFormat() -> String {
        return "%@"
    }
    func getPredicateValue() -> CVarArg {
        return self
    }
}
