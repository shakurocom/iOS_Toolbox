//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Vlad Onipchenko
//

import Foundation

/**
 NOTE: in case of unexpected -25300 & -25303 errors - make sure you have proper provision profile and dev/dist certificate
 */
public class KeychainWrapper {

    public enum Error: Swift.Error {
        case unexpectedKeychainItemData(queryResult: AnyObject?) // most probably can't decode sec value
        case encodeSecValueError(underlyingError: Swift.Error)
        case addKeychainItemError(osStatus: OSStatus)
        case readKeychainItemError(osStatus: OSStatus)
        case updateKeychainItemError(osStatus: OSStatus)
        case deleteKeychainItemError(osStatus: OSStatus)
        case searchKeychainError(osStatus: OSStatus)
    }

    public struct Item<T: Codable> {

        public let serviceName: String
        public let account: String
        public let itemName: String?
        public let accessGroup: String?
        public let secValue: T

        public init(serviceName: String, account: String, itemName: String?, accessGroup: String?, secValue: T) {
            self.serviceName = serviceName
            self.account = account
            self.itemName = itemName
            self.accessGroup = accessGroup
            self.secValue =  secValue
        }

    }

    // MARK: - Public

    /**
     - throws: KeychainWrapper.Error
     */
    public static func saveKeychainItem<T>(_ item: KeychainWrapper.Item<T>) throws where T: Encodable {
        let secValueData: Data
        do {
            secValueData = try JSONEncoder().encode(item.secValue)
        } catch let encodeError {
            throw KeychainWrapper.Error.encodeSecValueError(underlyingError: encodeError)
        }
        var error: KeychainWrapper.Error?
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
                error = KeychainWrapper.Error.addKeychainItemError(osStatus: status)
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
                error = KeychainWrapper.Error.updateKeychainItemError(osStatus: status)
            }
        default:
            error = KeychainWrapper.Error.searchKeychainError(osStatus: status)
        }
        if let realError = error {
            throw realError
        }
    }

    /**
     - throws: KeychainWrapper.Error
     */
    public static func removeKeychainItem(serviceName: String, account: String, accessGroup: String? = nil) throws {
        let searchQuery = makeKeychainQuery(serviceName: serviceName, account: account, accessGroup: accessGroup)
        let status = SecItemDelete(searchQuery as CFDictionary)
        guard status == noErr || status == errSecItemNotFound else {
            throw KeychainWrapper.Error.deleteKeychainItemError(osStatus: status)
        }
    }

    /**
     - throws: KeychainWrapper.Error
     */
    public static func keychainItem<T>(serviceName: String, account: String, accessGroup: String? = nil) throws -> KeychainWrapper.Item<T>? where T: Decodable {
        var result: KeychainWrapper.Item<T>?
        var error: KeychainWrapper.Error?
        var searchQuery: [String: Any] = makeKeychainQuery(serviceName: serviceName, account: account, accessGroup: accessGroup)
        searchQuery[kSecReturnData as String] = kCFBooleanTrue
        searchQuery[kSecReturnAttributes as String] = kCFBooleanTrue
        searchQuery[kSecMatchLimit as String] = kSecMatchLimitOne
        var queryResult: AnyObject?
        let status = SecItemCopyMatching(searchQuery as CFDictionary, &queryResult)
        switch status {
        case noErr:
            if let existingItem = queryResult as? [String: AnyObject],
                let serviceName = existingItem[kSecAttrService as String] as? String,
                let account = existingItem[kSecAttrAccount as String] as? String,
                let secValueData = existingItem[kSecValueData as String] as? Data,
                let secValue = try? JSONDecoder().decode(T.self, from: secValueData) {
                var itemName: String?
                if let itemNameData = existingItem[kSecAttrGeneric as String] as? Data {
                    itemName = String(data: itemNameData, encoding: String.Encoding.utf8)
                }
                var accessGroup: String?
                if let accessGroupValue = existingItem[kSecAttrAccessGroup as String] as? String {
                    accessGroup = accessGroupValue
                }
                result = KeychainWrapper.Item(serviceName: serviceName, account: account, itemName: itemName, accessGroup: accessGroup, secValue: secValue)
            } else {
                error = KeychainWrapper.Error.unexpectedKeychainItemData(queryResult: queryResult)
            }

        case errSecItemNotFound:
            result = nil

        default:
            error = KeychainWrapper.Error.readKeychainItemError(osStatus: status)
        }
        if let realError = error {
            throw realError
        }
        return result
    }

    /**
     Any invalid items will be skipped.
     - throws: KeychainWrapper.Error
     */
    public static func keychainItems<T>(serviceName: String, accessGroup: String? = nil) throws -> [KeychainWrapper.Item<T>] where T: Decodable {
        var resultItems: [KeychainWrapper.Item<T>] = []
        var error: KeychainWrapper.Error?
        var searchQuery: [String: Any] = makeKeychainQuery(serviceName: serviceName, accessGroup: accessGroup)
        searchQuery[kSecMatchLimit as String] = kSecMatchLimitAll
        searchQuery[kSecReturnAttributes as String] = kCFBooleanTrue
        searchQuery[kSecReturnData as String] = kCFBooleanTrue
        var queryResult: AnyObject?
        let status = SecItemCopyMatching(searchQuery as CFDictionary, &queryResult)
        switch status {
        case errSecItemNotFound:
            // do nothing
            break

        case noErr:
            if let existingItems = queryResult as? [[String: AnyObject]] {
                for existingItem in existingItems {
                    if let serviceName = existingItem[kSecAttrService as String] as? String,
                        let account = existingItem[kSecAttrAccount as String] as? String,
                        let secValueData = existingItem[kSecValueData as String] as? Data,
                        let secValue = try? JSONDecoder().decode(T.self, from: secValueData) {
                        var itemName: String?
                        if let itemNameData = existingItem[kSecAttrGeneric as String] as? Data {
                            itemName = String(data: itemNameData, encoding: String.Encoding.utf8)
                        }
                        var accessGroup: String?
                        if let accessGroupValue = existingItem[kSecAttrAccessGroup as String] as? String {
                            accessGroup = accessGroupValue
                        }
                        let keychainItem = KeychainWrapper.Item(serviceName: serviceName, account: account, itemName: itemName, accessGroup: accessGroup, secValue: secValue)
                        resultItems.append(keychainItem)
                    }
                }
            } else {
                error = KeychainWrapper.Error.unexpectedKeychainItemData(queryResult: queryResult)
            }

        default:
            error = KeychainWrapper.Error.readKeychainItemError(osStatus: status)
        }
        if let realError = error {
            throw realError
        }
        return resultItems
    }

    /**
     - throws: KeychainWrapper.Error
     */
    public static func removeKeychainItems(serviceName: String, accessGroup: String? = nil) throws {
        let searchQuery = makeKeychainQuery(serviceName: serviceName, accessGroup: accessGroup)
        let status = SecItemDelete(searchQuery as CFDictionary)
        guard status == noErr || status == errSecItemNotFound else {
            throw KeychainWrapper.Error.deleteKeychainItemError(osStatus: status)
        }
    }

    // MARK: - Private

    private static func makeKeychainQuery(serviceName: String, account: String? = nil, accessGroup: String? = nil) -> [String: String] {
        var query = [String: String]()
        query[kSecClass as String] = kSecClassGenericPassword as String
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
