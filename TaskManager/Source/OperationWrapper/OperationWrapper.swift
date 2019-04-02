//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

internal protocol OperationWrapperProtocol: CancellableOperation {
}

/**
 Base class for OperationWrappers. Abstract!
 */
internal class OperationWrapper<ResultType>: OperationWrapperProtocol {

    internal var isCancelled: Bool {
        fatalError("\(type(of: self)) is abstract!")
    }

    internal func cancel() {
        fatalError("\(type(of: self)) is abstract!")
    }

    func onComplete(queue: DispatchQueue?, closure: @escaping (AsyncResult<ResultType>) -> Void) {
        fatalError("\(type(of: self)) is abstract!")
    }

}
