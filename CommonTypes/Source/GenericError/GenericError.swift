import Foundation

// MARK: - PresentableError

protocol PresentableError: Error {
    var errorDescription: String {get}
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

    var errorDescription: String {
        return Interpreter.generateDescription(self)
    }

    init(_ value: Error) {
        self.value = value
    }

    func getValue<T>() -> T? {
        return value as? T ?? (value as? GenericErrorProtocol)?.getValue()
    }

    func isNotFoundError() -> Bool {
        return Interpreter.isNotFoundError(self)
    }

    func isNotAuthorizedError() -> Bool {
        return Interpreter.isNotAuthorizedError(self)
    }

    func isCancelledError() -> Bool {
        return Interpreter.isCancelledError(self)
    }

    func isRequestTimedOutError() -> Bool {
        return Interpreter.isRequestTimedOutError(self)
    }

    func isConnectionError() -> Bool {
        return Interpreter.isConnectionError(self)
    }

    func isInternalServerError() -> Bool {
        return Interpreter.isInternalServerError(self)
    }
}
