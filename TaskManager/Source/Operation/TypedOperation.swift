//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public protocol TypedOperation {

    /**
     Use this method to provide type of the operation - do not use `type(of:)` because in some cases internal operations will be added to queue.
     You MUST override this.
     - Example:
     ```
     return MyOperationTypeEnum.concreteOperation.rawValue
     ```
     */
    var operationType: Int { get }

}
