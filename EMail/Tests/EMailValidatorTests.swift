//
//
//

import XCTest
@testable import iOSToolboxExample

class EMailValidatorTests: XCTestCase {

    func testEmails() {
        let validEmails = [
            "example@gmail.com",
            "@@gmail.com",
            "123@gmail.com",
            "exa@gmail1.com",
            "exa@gmail.com1",
            "exa@mple@gmail.com",
            "exa@mple@gmail.com",
            "exa@mp le@gmail.com",
            "dünn@vögel.cöm",
            "тест@мыло.рф",
            "_м@мыло.рф",
            "_m@mail.com",
            "example@gmail.co",
            "Joe.Blow@example.com",
            "\"Abc@def\"@example.com",
            "customer/department=shipping@example.com",
            "$A12345@example.com",
            "!def!xyz%abc@example.com"
        ]
        let invalidEmails = [
            " example@gmail.com",
            "exa@mple@g.c",
            "exa@mple@g mail.com",
            "exa@mple@gmail.com "
        ]

        let validEmailsIfTrim = [
            "   example@gmail.com ",
            " @@gmail.com ",
            "  123@gmail.com  ",
            "exa@gmail1.com ",
            "\n  exa@gmail.com1 \n "]

        continueAfterFailure = true

        let validator = EMailValidator()

        // Valid
        let notPassedEmails = validEmails.filter({!validator.isValid(email: $0)})
        XCTAssert(notPassedEmails.count == 0, "valid emails not passed validation: \(notPassedEmails)")

        let notPassedTrimmedEmails = validEmailsIfTrim.filter({validator.validate(email: $0, shouldTrim: true) == nil})
        XCTAssert(notPassedTrimmedEmails.count == 0, "valid emails not passed validation: \(notPassedTrimmedEmails)")

        // bad
        let passedEmails = invalidEmails.filter({validator.isValid(email: $0)})
        XCTAssert(passedEmails.count == 0, "invalid emails passed validation: \(passedEmails)")

        let passedNotTrimmedEmails = validEmailsIfTrim.filter({validator.validate(email: $0, shouldTrim: false) != nil})
        XCTAssert(passedNotTrimmedEmails.count == 0, "invalid emails passed validation: \(passedNotTrimmedEmails)")
    }

}
