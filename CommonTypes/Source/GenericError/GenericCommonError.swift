import Foundation

enum GenericCommonError: Int, PresentableError {
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
