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
internal class OperationWrapper<ResultType>: OperationWrapperProtocol, TypedAsyncCompletionProtocol {

    internal var isCancelled: Bool {
        fatalError("\(type(of: self)) is abstract!")
    }

    internal func cancel() {
        fatalError("\(type(of: self)) is abstract!")
    }

    func onComplete(queue: DispatchQueue?, closure: @escaping (TaskResult<ResultType>) -> Void) {
        fatalError("\(type(of: self)) is abstract!")
    }

}

/**
 Simple operation wrapper.
 */
internal class TaskOperationWrapper<ResultType>: OperationWrapper<ResultType> {

    private let mainOperation: TaskOperation<ResultType>
    private let secondaryOperations: [AsyncCompletionProtocol]

    init(mainOperation: TaskOperation<ResultType>, secondaryOperations: [AsyncCompletionProtocol]) {
        self.mainOperation = mainOperation
        self.secondaryOperations = secondaryOperations
    }

    internal override var isCancelled: Bool {
        return mainOperation.isCancelled
    }

    internal override func cancel() {
        return mainOperation.cancel()
    }

    internal override func onComplete(queue: DispatchQueue?, closure: @escaping (TaskResult<ResultType>) -> Void) {
        mainOperation.onComplete(queue: queue, closure: closure)
    }

}

/**
 Enhanced wrapper with ability to retry.
 */
internal final class RetryTaskOperationWrapper<ResultType>: OperationWrapper<ResultType> {

    private enum State {
        case executing
        case finished(result: TaskResult<ResultType>)
    }

    private var mainOperation: TaskOperation<ResultType>
    private var secondaryOperations: [AsyncCompletionProtocol]
    private var state: State = .executing
    private let retryHandler: RetryBlock<ResultType>
    private var retryNumber: Int = 0
    private var completions: [OperationCallback<ResultType>] = []
    private let accessLock: NSRecursiveLock

    internal init(mainOperation: TaskOperation<ResultType>,
                  secondaryOperations: [AsyncCompletionProtocol],
                  retryHandler: @escaping RetryBlock<ResultType>) {
        self.mainOperation = mainOperation
        self.secondaryOperations = secondaryOperations
        self.retryHandler = retryHandler
        accessLock = NSRecursiveLock()
        accessLock.name = "\(type(of: self)).accessLock"
        super.init()
        handleOperations()
    }

    internal override var isCancelled: Bool {
        return mainOperation.isCancelled
    }

    internal override func cancel() {
        accessLock.execute({
            mainOperation.cancel()
        })
    }

    internal override func onComplete(queue: DispatchQueue?, closure: @escaping (TaskResult<ResultType>) -> Void) {
        let newCallback = OperationCallback(callbackQueue: queue, callback: closure)
        accessLock.execute({ () -> Void in
            switch state {
            case .executing:
                completions.append(newCallback)
            case .finished(let result):
                newCallback.performAsync(result: result)
            }
        })
    }

    private func handleOperations() {
        let group = DispatchGroup()
        secondaryOperations.forEach({ (operation) -> Void in
            group.enter()
            operation.onComplete(queue: nil, closure: { group.leave() })
        })
        group.enter()
        mainOperation.onComplete(queue: nil, closure: { group.leave() })
        group.notify(queue: DispatchQueue.global(), execute: { () -> Void in
            self.processMainOperationResult()
        })
    }

    private func processMainOperationResult() {
        accessLock.execute({
            // sanity check
            if case .finished = state {
                let log = "invalid state of \(type(of: self)): \(state)"
                assertionFailure(log)
            }
            guard let mainOperationResult = mainOperation.operationResult else {
                assertionFailure("\(type(of: self)): invalid result of main operation:" +
                    " operation expected to be completed and contain concrete result.")
                finish(result: .cancelled)
                return
            }
            let currentRetryNumber = retryNumber
            let retryAttemptResult = retryHandler(currentRetryNumber, isCancelled ? .cancelled : mainOperationResult)
            switch retryAttemptResult {
            case .finish:
                finish(result: mainOperationResult)
            case .retry(let newMainOperation, let newSecondaryOperations):
                retryNumber += 1
                mainOperation = newMainOperation
                secondaryOperations = newSecondaryOperations
                handleOperations()
            }
        })
    }

    private func finish(result: TaskResult<ResultType>) {
        state = .finished(result: result)
        for callback in completions {
            callback.performAsync(result: result)
        }
        completions.removeAll()
    }

}
