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
        // exponent -> result string value
        let testSample: [Double: String] = [2: "100",
                                            3: "1k",
                                            4: "10k",
                                            5: "100k",
                                            6: "1M",
                                            7: "10M",
                                            8: "100M",
                                            9: "1G",
                                            10: "10G",
                                            11: "100G",
                                            12: "1T",
                                            13: "10T",
                                            14: "100T",
                                            15: "1P",
                                            16: "10P",
                                            17: "100P",
                                            18: "1E",
                                            19: "10E"]
        testSample.forEach { (entry) in
            let value = pow(10, entry.0)
            let formattedValue = formatter.string(for: value)
            XCTAssertEqual(entry.1, formattedValue)
        }
    }

}
