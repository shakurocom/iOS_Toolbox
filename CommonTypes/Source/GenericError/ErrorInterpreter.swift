import Foundation

protocol ErrorInterpreterProtocol {

    static func generateDescription(_ error: Error) -> String

    static func isNotFoundError(_ error: GenericErrorProtocol) -> Bool
    static func isNotAuthorizedError(_ error: GenericErrorProtocol) -> Bool
    static func isCancelledError(_ error: GenericErrorProtocol) -> Bool
    static func isRequestTimedOutError(_ error: GenericErrorProtocol) -> Bool
    static func isConnectionError(_ error: GenericErrorProtocol) -> Bool
    static func isInternalServerError(_ error: GenericErrorProtocol) -> Bool
}

class ErrorInterpreter: ErrorInterpreterProtocol {

    static func generateDescription(_ error: Error) -> String {
        let dsc: String
        switch error {
        case let current as NetworkErrorConvertible:
            dsc = current.networkError().errorDescription
        case let current as PresentableError:
            dsc = current.errorDescription
        case let current as NSError:
            dsc = current.localizedDescription
        default:
            dsc = (error as? LocalizedError)?.errorDescription ?? "\(error)"
        }
        return dsc
    }

    static func isNotFoundError(_ error: GenericErrorProtocol) -> Bool {
        let networkError: NetworkErrorConvertible? = error.getValue()
        return networkError?.networkError().statusCode == 404
    }

    static func isNotAuthorizedError(_ error: GenericErrorProtocol) -> Bool {
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

    static func isCancelledError(_ error: GenericErrorProtocol) -> Bool {
        if let error: NSError = error.getValue() {
            return error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled
        }
        return false
    }

    static func isRequestTimedOutError(_ error: GenericErrorProtocol) -> Bool {
        if let error: NSError = error.getValue() {
            return error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut
        }
        return false

    }

    static func isConnectionError(_ error: GenericErrorProtocol) -> Bool {
        if let error: NSError = error.getValue() {
            return error.domain == NSURLErrorDomain && [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet].contains(error.code)
        }
        return false
    }

    static func isInternalServerError(_ error: GenericErrorProtocol) -> Bool {
        let networkError: NetworkErrorConvertible? = error.getValue()
        return networkError?.networkError().statusCode == 500
    }

    private init() {}
}
