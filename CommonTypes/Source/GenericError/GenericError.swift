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

struct GenericError<Interpreter: ErrorInterpreterProtocol>: GenericErrorProtocol {

    let value: Error
    let errorDescription: String

    let interpreter: Interpreter

    static func unknownError() -> GenericError<Interpreter> {
        return GenericError(value: GenericCommonError.unknown)
    }

    static func notAuthorizedError() -> GenericError<Interpreter> {
        return GenericError(value: GenericCommonError.notAuthorized)
    }

    init(value: Error) {
        self.init(errorDescription: Interpreter.generateDescription(value), value: value)
    }

    init(errorDescription: String, value: Error) {
        self.errorDescription = errorDescription
        self.value = value
        self.interpreter = Interpreter()
    }

    func getValue<T>() -> T? {
        return value as? T ?? (value as? GenericErrorProtocol)?.getValue()
    }
}

// MARK: - Interpreter

extension GenericError {
    func isNotFoundError() -> Bool {
        return interpreter.isNotFoundError(self)
    }
    func isNotAuthorizedError() -> Bool {
        return interpreter.isNotAuthorizedError(self)
    }
    func isCancelledError() -> Bool {
        return interpreter.isCancelledError(self)
    }
    func isRequestTimedOutError() -> Bool {
        return interpreter.isRequestTimedOutError(self)
    }
    func isConnectionError() -> Bool {
        return interpreter.isConnectionError(self)
    }

    func isInternalServerError() -> Bool {
      return interpreter.isInternalServerError(self)
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
