//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Vlad Onipchenko
//

import Foundation
//TODO: add tests

/**
 NOTE: in case of unexpected -25300 & -25303 errors - make sure you have proper provision profile and dev/dist certificate
 */
public class KeychainWrapper {

    public enum Error: Swift.Error {
        case notFound
        case unexpectedKeychainItemData(queryResult: AnyObject?)
        case encodeSecValueError
        case addKeychainItemError(osStatus: OSStatus)
        case readKeychainItemError(osStatus: OSStatus)
        case updateKeychainItemError(osStatus: OSStatus)
        case deleteKeychainItemError(osStatus: OSStatus)
        case searchKeychainError(osStatus: OSStatus)
    }

    public struct Item<T> where T: Codable {
        public let serviceName: String
        public let account: String
        public let itemName: String?
        public let accessGroup: String?
        public let secValue: T

        public init(serviceName: String, account: String, secValue: T, itemName: String? = nil, accessGroup: String? = nil) {
            self.serviceName = serviceName
            self.account = account
            self.itemName = itemName
            self.accessGroup = accessGroup
            self.secValue = secValue
        }

    }

    // MARK: - Public

    /**
     - throws: KeychainWrapper.Error
     */
    public static func saveKeychainItem<T>(_ item: KeychainWrapper.Item<T>) throws where T: Encodable {
        if let secValueData = try? JSONEncoder().encode(item.secValue) {
            var searchQuery: [String: Any] = makeKeychainQuery(serviceName: item.serviceName, account: item.account, accessGroup: item.accessGroup)
            searchQuery[kSecReturnData as String] = kCFBooleanTrue
            searchQuery[kSecReturnAttributes as String] = kCFBooleanTrue
            searchQuery[kSecMatchLimit as String] = kSecMatchLimitOne
            var status = SecItemCopyMatching(searchQuery as CFDictionary, nil)

            switch status {
            case errSecItemNotFound:
                var newItem: [String: Any] = makeKeychainQuery(serviceName: item.serviceName, account: item.account, accessGroup: item.accessGroup)
                newItem[kSecValueData as String] = secValueData
                if let itemName = item.itemName, let data = itemName.data(using: String.Encoding.utf8) {
                    newItem[kSecAttrGeneric as String] = data
                }
                status = SecItemAdd(newItem as CFDictionary, nil)
                if status != noErr {
                    throw KeychainWrapper.Error.addKeychainItemError(osStatus: status)
                }
            case noErr:
                let updateQuery: [String: Any] = makeKeychainQuery(serviceName: item.serviceName, account: item.account, accessGroup: item.accessGroup)
                var attributesToUpdate = [String: Any]()
                attributesToUpdate[kSecValueData as String] = secValueData
                if let itemName = item.itemName, let data = itemName.data(using: String.Encoding.utf8) {
                    attributesToUpdate[kSecAttrGeneric as String] = data
                }
                status = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
                if status != noErr {
                    throw KeychainWrapper.Error.updateKeychainItemError(osStatus: status)
                }
            default:
                throw KeychainWrapper.Error.searchKeychainError(osStatus: status)
            }
        } else {
            throw KeychainWrapper.Error.encodeSecValueError
        }
    }

    /**
     - throws: KeychainWrapper.Error
     */
    public static func removeKeychainItem(serviceName: String, account: String, accessGroup: String? = nil) throws {
        let searchQuery = makeKeychainQuery(serviceName: serviceName, account: account, accessGroup: accessGroup)
        let status = SecItemDelete(searchQuery as CFDictionary)
        guard status != errSecItemNotFound else {
            throw KeychainWrapper.Error.notFound
        }
        guard status == noErr else {
            throw KeychainWrapper.Error.deleteKeychainItemError(osStatus: status)
        }
    }

    /**
     - throws: KeychainWrapper.Error
     */
    public static func keychainItem<T>(serviceName: String, account: String, accessGroup: String? = nil) throws -> KeychainWrapper.Item<T> where T: Decodable {
        var searchQuery: [String: Any] = makeKeychainQuery(serviceName: serviceName, account: account, accessGroup: accessGroup)
        searchQuery[kSecReturnData as String] = kCFBooleanTrue
        searchQuery[kSecReturnAttributes as String] = kCFBooleanTrue
        searchQuery[kSecMatchLimit as String] = kSecMatchLimitOne
        var queryResult: AnyObject?
        let status = SecItemCopyMatching(searchQuery as CFDictionary, &queryResult)
        guard status != errSecItemNotFound else {
            throw KeychainWrapper.Error.notFound
        }
        guard status == noErr else {
            throw KeychainWrapper.Error.readKeychainItemError(osStatus: status)
        }
        guard let existingItem = queryResult as? [String : AnyObject],
            let kServiceName = existingItem[kSecAttrService as String] as? String,
            let account = existingItem[kSecAttrAccount as String] as? String,
            let secValueData = existingItem[kSecValueData as String] as? Data,
            let kSecValue = try? JSONDecoder().decode(T.self, from: secValueData) else {
                throw KeychainWrapper.Error.unexpectedKeychainItemData(queryResult: queryResult)
        }
        var kItemName: String?
        if let kItemNameData = existingItem[kSecAttrGeneric as String] as? Data {
            kItemName = String(data: kItemNameData, encoding: String.Encoding.utf8)
        }
        return KeychainWrapper.Item(serviceName: kServiceName, account: account, itemName: kItemName, secValue: kSecValue)
    }

    public static func keychainItems<T>(serviceName: String, accessGroup: String? = nil) throws -> [KeychainWrapper.Item<T>] where T: Decodable {
        var searchQuery: [String: Any] = makeKeychainQuery(serviceName: serviceName, accessGroup: accessGroup)
        searchQuery[kSecMatchLimit as String] = kSecMatchLimitAll
        searchQuery[kSecReturnAttributes as String] = kCFBooleanTrue
        searchQuery[kSecReturnData as String] = kCFBooleanFalse
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(searchQuery as CFDictionary, UnsafeMutablePointer($0))
        }
        guard status != errSecItemNotFound else {
            return []
        }
        guard status == noErr else {
            throw KeychainWrapper.Error.readKeychainItemError(osStatus: status)
        }
        guard let existingItems = queryResult as? [[String : AnyObject]] else {
            throw KeychainWrapper.Error.unexpectedKeychainItemData(queryResult: queryResult)
        }
        var resultItems = [KeychainWrapper.Item<T>]()
        for existingItem in existingItems {
            guard let kServiceName = existingItem[kSecAttrService as String] as? String,
                let account = existingItem[kSecAttrAccount as String] as? String,
                let secValueData = existingItem[kSecValueData as String] as? Data,
                let kSecValue = try? JSONDecoder().decode(T.self, from: secValueData) else {
                    throw KeychainWrapper.Error.unexpectedKeychainItemData(queryResult: queryResult)
            }
            var kItemName: String?
            if let kItemNameData = existingItem[kSecAttrGeneric as String] as? Data {
                kItemName = String(data: kItemNameData, encoding: String.Encoding.utf8)
            }
            let keychainItem = KeychainWrapper.Item(serviceName: kServiceName, account: account, itemName: kItemName, secValue: kSecValue)
            resultItems.append(keychainItem)
        }
        return resultItems
    }

    // MARK: - Private

    private static func makeKeychainQuery(serviceName: String, account: String? = nil, accessGroup: String? = nil) -> [String: String] {
        var query = [String : String]()
        query[kSecClass as String] = kSecClassGenericPassword  as String
        query[kSecAttrService as String] = serviceName
        if let account = account {
            query[kSecAttrAccount as String] = account
        }
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }

}

