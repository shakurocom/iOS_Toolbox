//
//  Copyright © 2019 Shakuro. All rights reserved.
//

import XCTest

class ShortNumberFormatterTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFormatter() {
        let formatter: ShortNumberFormatter = ShortNumberFormatter()
        let results: [String] = ["100",
                                 "1k",
                                 "10k",
                                 "100k",
                                 "1M",
                                 "10M",
                                 "100M",
                                 "1G",
                                 "10G",
                                 "100G",
                                 "1T",
                                 "10T",
                                 "100T",
                                 "1P",
                                 "10P",
                                 "100P",
                                 "1E",
                                 "10E"]
        for (index, exponent) in (2...19).enumerated() {
            let value = pow(10, Double(exponent))
            let formattedValue = formatter.string(for: value)
            XCTAssertEqual(results[index], formattedValue)
        }
    }

}
