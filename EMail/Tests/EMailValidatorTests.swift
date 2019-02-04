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

        continueAfterFailure = true

        let validator = EMailValidator()
        var notPassedEmails = [String]()

        // good
        for email in validEmails {
            if !validator.validate(emailString: email) {
                notPassedEmails.append(email)
            }
        }
        XCTAssert(notPassedEmails.count == 0, "valid emails not passed validation: \(notPassedEmails)")

        // bad
        var passedEmails = [String]()
        for email in invalidEmails {
            if validator.validate(emailString: email) {
                passedEmails.append(email)
            }
        }
        XCTAssert(passedEmails.count == 0, "invalid emails passed validation: \(passedEmails)")
    }

}
