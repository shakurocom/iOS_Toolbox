//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public protocol ExecuteSyncProtocol {
    func execute<ResultType>(_ closure: () -> ResultType) -> ResultType
}

extension NSLock: ExecuteSyncProtocol {

    public func execute<ResultType>(_ closure: () -> ResultType) -> ResultType {
        let result: ResultType
        lock()
        result = closure()
        unlock()
        return result
    }

}

extension NSRecursiveLock: ExecuteSyncProtocol {

    public func execute<ResultType>(_ closure: () -> ResultType) -> ResultType {
        let result: ResultType
        lock()
        result = closure()
        unlock()
        return result
    }

}
