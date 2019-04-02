//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public enum AsyncResult<ResultType> {

    case success(result: ResultType)
    case cancelled
    case failure(error: Error)

    public func voidTyped() -> AsyncResult<Void> {
        switch self {
        case .success: return .success(result: ())
        case .cancelled: return .cancelled
        case .failure(let error): return .failure(error: error)
        }
    }

}
