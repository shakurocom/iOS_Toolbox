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

    public let predicate: NSPredicate = NSPredicate(format: "SELF MATCHES %@", "^\\S.*@(\\S+\\.)+\\S{2}\\S*$")

    public init() { }

    public func isValid(email: String) -> Bool {
        return predicate.evaluate(with: email)
    }

    public func validate(email: String, shouldTrim: Bool) -> String? {
        let candidate = shouldTrim ? email.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) : email
        return isValid(email: candidate) ? candidate : nil
    }

}
