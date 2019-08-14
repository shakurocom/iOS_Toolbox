import Foundation

protocol ErrorInterpreterProtocol {

    init()

    static func generateDescription(_ error: Error) -> String

    func isNotFoundError(_ error: GenericErrorProtocol) -> Bool
    func isNotAuthorizedError(_ error: GenericErrorProtocol) -> Bool
    func isCancelledError(_ error: GenericErrorProtocol) -> Bool
    func isRequestTimedOutError(_ error: GenericErrorProtocol) -> Bool
    func isConnectionError(_ error: GenericErrorProtocol) -> Bool
    func isInternalServerError(_ error: GenericErrorProtocol) -> Bool
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

    required init() {}

    func isNotFoundError(_ error: GenericErrorProtocol) -> Bool {
        let networkError: NetworkErrorConvertible? = error.getValue()
        return networkError?.networkError().statusCode == 404
    }

    func isNotAuthorizedError(_ error: GenericErrorProtocol) -> Bool {
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

    func isCancelledError(_ error: GenericErrorProtocol) -> Bool {
        if let error: NSError = error.getValue() {
            return error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled
        }
        return false
    }

    func isRequestTimedOutError(_ error: GenericErrorProtocol) -> Bool {
        if let error: NSError = error.getValue() {
            return error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut
        }
        return false

    }

    func isConnectionError(_ error: GenericErrorProtocol) -> Bool {
        if let error: NSError = error.getValue() {
            return error.domain == NSURLErrorDomain && [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet].contains(error.code)
        }
        return false
    }

    func isInternalServerError(_ error: GenericErrorProtocol) -> Bool {
        let networkError: NetworkErrorConvertible? = error.getValue()
        return networkError?.networkError().statusCode == 500
    }
}
