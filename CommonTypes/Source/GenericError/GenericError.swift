import Foundation

// MARK: - PresentableError

protocol PresentableError: Error {
    var errorDescription: String {get}
}

// MARK: - GenericCommonError

enum GenericCommonError: Int, PresentableError {
    case notAuthorized = 101
    case unknown = 102
}

// MARK: - GenericError

typealias DefaultGenericError = GenericError<ErrorInterpreter>

protocol GenericErrorProtocol: PresentableError {
    var value: Error {get}
    var errorDescription: String {get}

    func getValue<T>() -> T?
}

struct GenericError<Interpreter>: GenericErrorProtocol {

    let value: Error
    let errorDescription: String

    static func unknownError() -> GenericError<Interpreter> {
        return GenericError(value: GenericCommonError.unknown)
    }

    static func notAuthorizedError() -> GenericError<Interpreter> {
        return GenericError(value: GenericCommonError.notAuthorized)
    }

    init(value: Error) {
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
        self.init(errorDescription: dsc, value: value)
    }

    init(errorDescription: String, value: Error) {
        self.errorDescription = errorDescription
        self.value = value
    }

    func getValue<T>() -> T? {
        return value as? T ?? (value as? GenericErrorProtocol)?.getValue()
    }
}

// MARK: - CommonError PresentableError

extension GenericCommonError {
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
