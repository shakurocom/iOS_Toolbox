import Foundation

class ErrorInterpreter {

    class func isNotFoundError(_ error: GenericErrorProtocol) -> Bool {
        let networkError: NetworkErrorConvertible? = error.getValue()
        return networkError?.networkError().statusCode == 404
    }

    class func isNotAuthorizedError(_ error: GenericErrorProtocol) -> Bool {
        if let error: GenericCommonError = error.getValue() {
            return error == .notAuthorized
        }
        if let error: NetworkErrorConvertible = error.getValue() {
            return error.networkError().statusCode == 401
        }
        if let error: NSError = error.getValue() {
            return error.domain == NSURLErrorDomain && error.code == NSURLErrorUserAuthenticationRequired
        }
        return false
    }

    class func isCancelledError(_ error: GenericErrorProtocol) -> Bool {
        if let error: NSError = error.getValue() {
            return error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled
        }
        return false
    }

    class  func isRequestTimedOutError(_ error: GenericErrorProtocol) -> Bool {
        if let error: NSError = error.getValue() {
            return error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut
        }
        return false

    }

    class func isConnectionError(_ error: GenericErrorProtocol) -> Bool {
        if let error: NSError = error.getValue() {
            return error.domain == NSURLErrorDomain && [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet].contains(error.code)
        }
        return false
    }

    class func isInternalServerError(_ error: GenericErrorProtocol) -> Bool {
        let networkError: NetworkErrorConvertible? = error.getValue()
        return networkError?.networkError().statusCode == 500
    }

    private init() {}
}
