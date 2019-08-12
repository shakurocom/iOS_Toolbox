import UIKit
import Alamofire

// MARK: - PresentableError

protocol PresentableError: Error {
    var errorDescription: String {get}
}

// MARK: - GlobalError

enum GlobalError: Int, PresentableError {

    case notAuthorized = 101
    case unknown = 102

    var errorDescription: String {
        let dsc: String
        switch self {
        case .notAuthorized:
            dsc = NSLocalizedString("The operation could not be completed. Not authorized.", comment: "")
        case .unknown:
            dsc = NSLocalizedString("The operation could not be completed.", comment: "")
        }
        return dsc
    }
}

// MARK: - GenericError

struct GenericError: PresentableError {

    let value: Error
    let underlyingValue: Error?
    let errorDescription: String

    init(value: Error, underlyingValue: Error? = nil) {
        let dsc: String
        switch value {
        case let current as NetworkErrorConvertible:
            dsc = current.networkError().errorDescription
        case let current as PresentableError:
            dsc = current.errorDescription
        case let current as NSError:
            dsc = current.localizedDescription
        default:
            dsc = (value as? LocalizedError)?.errorDescription ?? "\(value)"
        }
        self.init(errorDescription: dsc, value: value, underlyingValue: underlyingValue)
    }

    init(errorDescription: String, value: Error, underlyingValue: Error? = nil) {
        self.errorDescription = errorDescription
        self.value = value
        self.underlyingValue = underlyingValue
    }

    func getValue<T>() -> T? {
        return value as? T ?? (value as? GenericError)?.getValue()
    }

    func getUnderlyingValue<T>() -> T? {
        return underlyingValue as? T ?? (underlyingValue as? GenericError)?.getUnderlyingValue()
    }
}
