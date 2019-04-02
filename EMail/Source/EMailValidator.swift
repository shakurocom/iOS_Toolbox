//
// Copyright (c) 2018-2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

/**
 Simple validator of email address designed to be used on client side.
 Very lax validation:
    1) at least 1 non-white symbol before '@'
    2) '@'
    3) at least one symbol after '@'
    4) '.'
    5) at least 2 characters in the end
 See tests for example emails.
 */
public class EMailValidator {

    public static func predicate() -> NSPredicate {
        return NSPredicate(format: "SELF MATCHES %@", "^\\S.*@(\\S+\\.)+\\S{2}\\S*$")
    }

    private let predicate: NSPredicate = EMailValidator.predicate()

    public func validate(emailString: String) -> Bool {
        return predicate.evaluate(with: emailString)
    }

}
