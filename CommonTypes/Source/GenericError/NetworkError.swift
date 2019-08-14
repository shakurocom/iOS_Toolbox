import Foundation

protocol NetworkErrorConvertible {
    func networkError() -> NetworkError
}

struct NetworkError: PresentableError, NetworkErrorConvertible {

    enum Value {
        case invalidHTTPStatusCode(Int)
        case apiError(status: Int, faultCode: String, errorDescription: String)
        case generalError(errorDescription: String)
    }

    let requestURL: URL?
    let value: Value
    let errorDescription: String

    var statusCode: Int? {
        switch value {
        case .invalidHTTPStatusCode(let status), .apiError(let status, _, _):
            return status
        case .generalError:
            return nil
        }
    }

    init(value: Value, requestURL: URL?) {
        self.value = value
        self.requestURL = requestURL
        switch value {
        case .invalidHTTPStatusCode(let status):
            let codeDsc: String = HTTPURLResponse.localizedString(forStatusCode: status)
            errorDescription = NSLocalizedString("Response status code was unacceptable:", comment: "") + " \(status) (\(codeDsc))"
        case .apiError(_, _, let apiErrorDescription):
            errorDescription = apiErrorDescription
        case .generalError(let generalErrorDescription):
            errorDescription = generalErrorDescription
        }
    }

    func networkError() -> NetworkError {
        return self
    }
}
