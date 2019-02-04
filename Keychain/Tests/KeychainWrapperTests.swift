//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import XCTest
@testable import iOSToolboxExample

class KeychainWrapperTests: XCTestCase {

    private struct KeychainData: Codable {
        let value1: String
        let value2: String
    }

    private enum Constant {
        static let serviceName: String = "com.shakuro.iOSToolboxTests.keychainWrapperTest"
        static let accountName: String = "TestingValues"
        static let itemName: String = ""
        static let invalidServiceName: String = serviceName + ".invalid"
        static let etalonData: KeychainData = KeychainData(value1: "111", value2: "222")
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testReadWriteRemove() {
        // 1) read - there should be no items in keychain
        do {
            let nilItem: KeychainWrapper.Item<KeychainData>? = try KeychainWrapper.keychainItem(serviceName: Constant.serviceName, account: Constant.accountName)
            XCTAssertNil(nilItem, "unexpected item found in keychain")
        } catch let error {
            XCTFail("\(error)")
        }
        do {
            let nilItem: KeychainWrapper.Item<KeychainData>? = try KeychainWrapper.keychainItem(serviceName: Constant.invalidServiceName, account: Constant.accountName)
            XCTAssertNil(nilItem, "unexpected item found in keychain")
        } catch let error {
            XCTFail("\(error)")
        }

        // 2) save etalon data
        do {
            let keychainItem = KeychainWrapper.Item(serviceName: Constant.serviceName, account: Constant.accountName, itemName: Constant.itemName, accessGroup: nil, secValue: Constant.etalonData)
            try KeychainWrapper.saveKeychainItem(keychainItem)
        } catch let error {
            XCTFail("\(error)")
        }

        // 3) read data back
        do {
            let keychainItem: KeychainWrapper.Item<KeychainData>? = try KeychainWrapper.keychainItem(serviceName: Constant.serviceName, account: Constant.accountName)
            let keychainItemNotNil = try assertNotNilAndUnwrap(keychainItem)
            XCTAssertEqual(keychainItemNotNil.serviceName, Constant.serviceName)
            XCTAssertEqual(keychainItemNotNil.account, Constant.accountName)
            let itemNameNotNil = try assertNotNilAndUnwrap(keychainItemNotNil.itemName)
            XCTAssertEqual(itemNameNotNil, Constant.itemName)
            XCTAssertEqual(keychainItemNotNil.secValue.value1, Constant.etalonData.value1)
            XCTAssertEqual(keychainItemNotNil.secValue.value2, Constant.etalonData.value2)
        } catch let error {
            XCTFail("\(error)")
        }

        // 4) read data with invalid service name
        do {
            let keychainItem: KeychainWrapper.Item<KeychainData>? = try KeychainWrapper.keychainItem(serviceName: Constant.invalidServiceName, account: Constant.accountName)
            XCTAssertNil(keychainItem)
        } catch let error {
            XCTFail("\(error)")
        }

        // 5) read data of invalid type
        do {
            let keychainItem: KeychainWrapper.Item<String>? = try KeychainWrapper.keychainItem(serviceName: Constant.serviceName, account: Constant.accountName)
            XCTFail("there should be an error in previous line. Returned result: \(String(describing: keychainItem))")
        } catch let error as KeychainWrapper.Error {
            switch error {
            case .unexpectedKeychainItemData:
                // this is the expected result
                break

            default:
                XCTFail("\(error)")
            }
        } catch let error {
            XCTFail("\(error)")
        }

        // 6) delete item
        do {
            try KeychainWrapper.removeKeychainItem(serviceName: Constant.serviceName, account: Constant.accountName)
        } catch let error {
            XCTFail("\(error)")
        }

        // 7) read after deletion
        do {
            let nilItem: KeychainWrapper.Item<KeychainData>? = try KeychainWrapper.keychainItem(serviceName: Constant.serviceName, account: Constant.accountName)
            XCTAssertNil(nilItem)
        } catch let error {
            XCTFail("\(error)")
        }
    }

}
