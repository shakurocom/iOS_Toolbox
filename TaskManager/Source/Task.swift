//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

/**
 Result of an operation (task).
 */
public enum TaskResult<ResultType> {
    case success(result: ResultType)
    case failure(error: Error)
}

/**
 A 'token' for a paticular task. You are not required to strongly hold this.
 */
public final class Task<ResultType> {

    private let operationWrapper: OperationWrapper<ResultType>

    internal init(operationWrapper: OperationWrapper<ResultType>) {
        self.operationWrapper = operationWrapper
    }

    /**
     Cancel operation related to this task. You can call this method multiple times.
     */
    public func cancel() {
        operationWrapper.cancel()
    }

    /**
     `true` if related operation is cancelled.
     */
    public var isCancelled: Bool {
        return operationWrapper.isCancelled
    }

    /**
     Add completion for this task. One task can have several completion blocks attached.
     - parameter queue: if `nil` `DispathQueue.global()` will be used. Default value is `nil`.
     - parameter closure: completion block. Will be executed asynchroniously on a specified queue.
     */
    public func onComplete(queue: DispatchQueue? = nil,
                           closure: @escaping (_ task: Task<ResultType>, _ result: AsyncResult<ResultType>) -> Void) {
        operationWrapper.onComplete(queue: queue, closure: { (result: AsyncResult<ResultType>) in
            closure(self, result)
        })
    }

}
