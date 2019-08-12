import Foundation

extension GenericError {

    static func unknownError() -> GenericError {
        return GenericError(value: GlobalError.unknown)
    }

    static func notAuthorizedError() -> GenericError {
        return GenericError(value: GlobalError.notAuthorized)
    }

    func isNotFoundError() -> Bool {
        let networkError: NetworkErrorConvertible? = getValue()
        return networkError?.networkError().statusCode == 404
    }

    func isNotAuthorizedError() -> Bool {
        if let error: GlobalError = getValue() {
            return error == .notAuthorized
        }
        if let error: NetworkErrorConvertible = getValue() {
            return error.networkError().statusCode == 401
        }
        if let error: NSError = getValue() {
            return error.domain == NSURLErrorDomain && error.code == NSURLErrorUserAuthenticationRequired
        }
        return false
    }

    func isCancelledError() -> Bool {
        if let error: NSError = getValue() {
            return error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled
        }
        return false
    }

    func isRequestTimedOutError() -> Bool {
        if let error: NSError = getValue() {
            return error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut
        }
        return false

    }

    func isConnectionError() -> Bool {
        if let error: NSError = getValue() {
            return error.domain == NSURLErrorDomain && [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet].contains(error.code)
        }
        return false
    }

    func isInternalServerError() -> Bool {
        let networkError: NetworkErrorConvertible? = getValue()
        return networkError?.networkError().statusCode == 500
    }
}
