//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public protocol ExecuteSyncProtocol {
    func execute<ResultType>(_ closure: () -> ResultType) -> ResultType
    func execute<ResultType>(_ closure: () throws -> ResultType) throws -> ResultType
}

extension NSLock: ExecuteSyncProtocol {

    public func execute<ResultType>(_ closure: () -> ResultType) -> ResultType {
        let result: ResultType
        lock()
        result = closure()
        unlock()
        return result
    }

    public func execute<ResultType>(_ closure: () throws -> ResultType) throws -> ResultType {
        let result: ResultType
        lock()
        do {
            result = try closure()
            unlock()
            return result
        } catch let error {
            unlock()
            throw error
        }
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

    public func execute<ResultType>(_ closure: () throws -> ResultType) throws -> ResultType {
        let result: ResultType
        lock()
        do {
            result = try closure()
            unlock()
            return result
        } catch let error {
            unlock()
            throw error
        }
    }

}
