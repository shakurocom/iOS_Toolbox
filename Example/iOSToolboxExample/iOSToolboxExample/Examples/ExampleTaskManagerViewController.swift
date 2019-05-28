//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

private enum MyOperationType: Int {
    case first = 1
    case unique
    case lowPriority
    case highPriority
    case alwaysFailInTheEnd
    case dependsOnAlwaysFail
}

internal class ExampleTaskManager: TaskManager {

    private let randomOrgClient: HTTPClient

    init(name aName: String, qualityOfService: QualityOfService, maxConcurrentOperationCount: Int, randomOrgClient aRandomOrgClient: HTTPClient) {
        randomOrgClient = aRandomOrgClient
        super.init(name: aName, qualityOfService: qualityOfService, maxConcurrentOperationCount: maxConcurrentOperationCount)
    }

    public required init(name aName: String, qualityOfService: QualityOfService, maxConcurrentOperationCount: Int) {
        fatalError("init(name:qualityOfService:maxConcurrentOperationCount:) has not been implemented")
    }

    override func willPerformOperation(newOperation: TaskManager.OperationInQueue,
                                       enqueuedOperations: [TaskManager.OperationInQueue]) -> TaskManager.OperationInQueue {
        let result: TaskManager.OperationInQueue
        switch newOperation.operationType {
        case MyOperationType.unique.rawValue:
            let uniqueInQueue = enqueuedOperations.first(where: { (operation: TaskManager.OperationInQueue) -> Bool in
                return operation.operationType == MyOperationType.unique.rawValue
            })
            result = uniqueInQueue ?? newOperation

        case MyOperationType.dependsOnAlwaysFail.rawValue:
            let dependencyInQueue = enqueuedOperations.first(where: { (operation: TaskManager.OperationInQueue) -> Bool in
                return operation.operationType == MyOperationType.alwaysFailInTheEnd.rawValue
            })
            if let actualDependency = dependencyInQueue {
                newOperation.addDependency(operation: actualDependency, isStrongDependency: true)
            }
            result = newOperation

        default:
            result = newOperation
        }
        return result
    }

}

// NOTE: those kind of method usually will go into protocol that is accessible for various view controllers
extension ExampleTaskManager {

    internal func doFirstOperation() -> Task<Int> {
        return performOperation(operationType: FirstOperation.self, options: ExampleOperationOptions())
    }

    internal func doUniqueOperation() -> Task<Int> {
        return performOperation(operationType: UniqueOperation.self, options: ExampleOperationOptions())
    }

    internal func doLowPriorityOperation() -> Task<Int> {
        return performOperation(operationType: LowPriorityOperation.self, options: ExampleOperationOptions())
    }

    internal func doHighPriorityOperation() -> Task<Int> {
        return performOperation(operationType: HighPriorityOperation.self, options: ExampleOperationOptions())
    }

    internal func doDependsOnAlwaysFailOperation() -> Task<Int> {
        return performOperation(operationType: DependsOnAlwaysFailOperation.self, options: ExampleOperationOptions())
    }

    internal func doAlwaysFailInTheEndOperation(retryHandler: RetryHandler<Int>?) -> Task<Int> {
        let group = OperationGroup(mainOperationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
        group.addSecondaryOperation(operationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
        group.addSecondaryOperation(operationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
        return performGroup(group, retryHandler: retryHandler)
    }

    internal func requestTenStringsFromRansomOrg() -> Task<String> {
        let options = GetStringsFromRandomOrgOperationOptions(randomOrgClient: randomOrgClient)
        return performOperation(operationType: GetStringsFromRandomOrgOperation.self, options: options)
    }

    internal func retryAlwaysFailThreeTimes() -> Task<Int> {
        let retryCountMax = 3
        return doAlwaysFailInTheEndOperation(retryHandler: RetryHandler(
            retryCondition: { (retryNumber, taskResult) -> Bool in
                switch taskResult {
                case .success:
                    return false
                case .failure:
                    // process error
                    if retryNumber < retryCountMax {
                        print("retrying...")
                        return true
                    } else {
                        print("retrying no more.")
                        return false
                    }
                }
            },
            willRetry: { print("will retry: attempt: \($0) result: \($1)") },
            didRetry: { print("did retry: attempt: \($0) result: \($1)") })
        )
    }

}

internal struct ExampleOperationOptions { }

internal class FirstOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        let numberOfSteps: Int = 10
        for index in 1...numberOfSteps {
            print("FirstOperation: substep #\(index) / \(numberOfSteps)")
            Thread.sleep(forTimeInterval: 0.5)
            if isCancelled {
                break
            }
        }
        if isCancelled {
            finish(result: .cancelled)
        } else {
            finish(result: .success(result: numberOfSteps))
        }
    }

    internal override var operationType: Int {
        return MyOperationType.first.rawValue
    }

    internal override var priorityValue: Int {
        return 0
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}

internal class UniqueOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        let numberOfSteps: Int = 15
        for index in 1...15 {
            print("UniqueOperation: substep #\(index) / \(numberOfSteps)")
            Thread.sleep(forTimeInterval: 0.5)
        }
        finish(result: .success(result: numberOfSteps))
    }

    internal override var operationType: Int {
        return MyOperationType.unique.rawValue
    }

    internal override var priorityValue: Int {
        return 0
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}

internal class LowPriorityOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        Thread.sleep(forTimeInterval: 1.0)
        print("LowPriorityOperation")
        finish(result: .success(result: priorityValue))
    }

    internal override var operationType: Int {
        return MyOperationType.lowPriority.rawValue
    }

    internal override var priorityValue: Int {
        return 0
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}

internal class HighPriorityOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        Thread.sleep(forTimeInterval: 1.0)
        print("HighPriorityOperation")
        finish(result: .success(result: priorityValue))
    }

    internal override var operationType: Int {
        return MyOperationType.highPriority.rawValue
    }

    internal override var priorityValue: Int {
        return 100
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}

internal class AlwaysFailInTheEndOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        let stepCount: Int = 10
        for step in 1...stepCount {
            Thread.sleep(forTimeInterval: 0.5)
            print("AlwaysFailsInTheEndOperation: step \(step) / \(stepCount)")
        }
        finish(result: .failure(error: NSError(domain: "ExampleErrorDomain", code: 9001, userInfo: nil)))
    }

    internal override var operationType: Int {
        return MyOperationType.alwaysFailInTheEnd.rawValue
    }

    internal override var priorityValue: Int {
        return 1
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}

internal class DependsOnAlwaysFailOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        Thread.sleep(forTimeInterval: 1.0)
        print("DependsOnAlwaysFailOperation")
        finish(result: .success(result: priorityValue))
    }

    internal override var operationType: Int {
        return MyOperationType.dependsOnAlwaysFail.rawValue
    }

    internal override var priorityValue: Int {
        return 1000
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.lifo
    }

}

internal struct GetStringsFromRandomOrgOperationOptions {
    let randomOrgClient: HTTPClient
}

internal class GetStringsFromRandomOrgOperation: BaseOperation<String, GetStringsFromRandomOrgOperationOptions> {

    private var request: HTTPClientRequest?

    override func main() {
        var requestOptions = HTTPClient.RequestOptions(
            method: HTTPClient.RequestMethod.GET,
            endpoint: RandomOrgAPIEndpoint.strings,
            parser: StringsParser.self)
        requestOptions.parameters = [
            "num": "10",
            "len": "10",
            "digits": "on",
            "unique": "on",
            "format": "plain",
            "rnd": "new"
        ]
        requestOptions.completionHandler = { [weak self] (parsedResponse, _) in
            guard let strongSelf = self else {
                return
            }
            switch parsedResponse {
            case .success(let networkResult):
                strongSelf.finish(result: .success(result: networkResult))
            case .cancelled:
                strongSelf.finish(result: .cancelled)
            case .failure(let networkError):
                strongSelf.finish(result: .failure(error: networkError))
            }
        }
        request = options.randomOrgClient.sendRequest(options: requestOptions)
    }

    override func internalCancel() {
        request?.cancel()
    }

    internal override var operationType: Int {
        return MyOperationType.dependsOnAlwaysFail.rawValue
    }

    internal override var priorityValue: Int {
        return 9001
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.lifo
    }

}

internal class ExampleTaskManagerViewController: UIViewController {

    @IBOutlet private var operationButton1: UIButton!
    @IBOutlet private var operationButton2: UIButton!
    @IBOutlet private var operationButton3: UIButton!
    @IBOutlet private var operationButton4: UIButton!
    @IBOutlet private var operationButton5: UIButton!
    @IBOutlet private var operationButton6: UIButton!
    @IBOutlet private var operationButton7: UIButton!

    private var example: Example?
    private let taskManager: ExampleTaskManager

    required init?(coder aDecoder: NSCoder) {
        let randomOrgClient = HTTPClient(
            name: "RandomOrgClient",
            acceptableContentTypes: ["text/plain"])
        taskManager = ExampleTaskManager(
            name: "com.shakuro.iOSToolboxExample.ExampleTaskManager",
            qualityOfService: QualityOfService.utility,
            maxConcurrentOperationCount: 6,
            randomOrgClient: randomOrgClient)
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title

        operationButton1.isExclusiveTouch = true
        operationButton1.setTitle("1st operation", for: UIControl.State.normal)
        operationButton2.isExclusiveTouch = true
        operationButton2.setTitle("2nd operation (unique)", for: UIControl.State.normal)
        operationButton3.isExclusiveTouch = true
        operationButton3.setTitle("10 x low + 10 x high priority", for: UIControl.State.normal)
        operationButton4.isExclusiveTouch = true
        operationButton4.setTitle("dependent operation", for: UIControl.State.normal)
        operationButton5.isExclusiveTouch = true
        operationButton5.setTitle("start & cancel 1st", for: UIControl.State.normal)
        operationButton6.isExclusiveTouch = true
        operationButton6.setTitle("get ten strings from random.org", for: UIControl.State.normal)
        operationButton7.isExclusiveTouch = true
        operationButton7.setTitle("retry operation 3 times", for: UIControl.State.normal)
    }

    @IBAction private func operationButton1Tapped() {
        let task = taskManager.doFirstOperation()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("operationButton1Tapped() completion. result: \(result)")
        })
    }

    @IBAction private func operationButton2Tapped() {
        let task = taskManager.doUniqueOperation()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("operationButton2Tapped() completion. result: \(result)")
        })
    }

    @IBAction private func operationButton3Tapped() {
        for _ in 1...10 {
            _ = taskManager.doLowPriorityOperation()
        }
        for _ in 1...10 {
            _ = taskManager.doHighPriorityOperation()
        }
    }

    @IBAction private func operationButton4Tapped() {
        let task1 = taskManager.doAlwaysFailInTheEndOperation(retryHandler: nil)
        task1.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("AlwaysFailInTheEndOperation finished with '\(result)'")
        })
        let task2 = taskManager.doDependsOnAlwaysFailOperation()
        task2.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("DependsOnAlwaysFailOperation finished with '\(result)'")
        })
    }

    @IBAction private func operationButton5Tapped() {
        let task1 = taskManager.doFirstOperation()
        task1.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("first operation completion (should be cancelled): \(result)")
        })
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1), execute: {
            task1.cancel()
            print("operation is now cancelled: \(task1.isCancelled)")
        })
    }

    @IBAction private func operationButton6Tapped() {
        let task = taskManager.requestTenStringsFromRansomOrg()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("data from random.org:\n \(result)")
        })
    }

    @IBAction private func operationButton7Tapped() {
        let task = taskManager.retryAlwaysFailThreeTimes()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("retry three times finished: \(result)")
        })
    }

}

// MARK: ExampleViewControllerProtocol

extension ExampleTaskManagerViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleTaskManagerViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleTaskManagerViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
