//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public protocol CancellableOperation: class {

    var isCancelled: Bool { get }

    func cancel()

}

extension Operation: CancellableOperation {
}
