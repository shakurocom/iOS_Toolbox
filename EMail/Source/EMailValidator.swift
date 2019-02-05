//
//
//

import Foundation

/**
 Simple validator of email address designed to be used on client side.
 Very lax validation:
    1) at least 1 non-white symbol before '@'
    2) '@'
    3) at least one symbol after '@'
    4) '.' and at least 2 characters in the end
 See tests for example emails.
 */
internal class EMailValidator {

    private let predicate: NSPredicate = NSPredicate(format: "SELF MATCHES %@", "^\\S.*@(\\S+\\.)+\\S{2}\\S*$")

    internal func validate(emailString: String) -> Bool {
        return predicate.evaluate(with: emailString)
    }

}
