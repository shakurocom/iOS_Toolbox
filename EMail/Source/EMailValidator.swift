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

    /// The NSPredicate used to validate email string
    public let predicate: NSPredicate = NSPredicate(format: "SELF MATCHES %@", "^\\S.*@(\\S+\\.)+\\S{2}\\S*$")

    public init() { }

    /// Returns true if email is valid, false otherwise
    /// See also: [validate(email: String, shouldTrim: Bool) -> String?](x-source-tag://EMailValidator.validate)
    ///
    /// - Parameter email: An email string to validate
    /// - Tag: EMailValidator.isValid
    public func isValid(email: String) -> Bool {
        return predicate.evaluate(with: email)
    }

    /// - Tag: EMailValidator.validate

    /// Returns valid email string or nil
    /// See also: [isValid(email: String) -> Bool ](x-source-tag://EMailValidator.isValid)
    ///
    /// - Parameters:
    ///   - email:  An email string to validate
    ///   - shouldTrim: Pass true to trim white spaces and newline before validation.
    /// - Returns: Valid email or nil
    public func validate(email: String, shouldTrim: Bool) -> String? {
        let candidate = shouldTrim ? email.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) : email
        return isValid(email: candidate) ? candidate : nil
    }

}
