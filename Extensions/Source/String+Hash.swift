//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Andrey Popov
//

import Foundation
import CommonCryptoModule

// MARK: - SHA512, MD5

extension String {

    public func SHA512() -> String? {
        guard let data = self.data(using: String.Encoding.utf8) else {
            return nil
        }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes { (unsafeBytes) -> Void in
            CC_SHA512(unsafeBytes, CC_LONG(data.count), &digest)
        }
        let output = digest.reduce("", {$0 + String(format: "%02x", $1)})
        return output
    }

    public func MD5() -> String? {
        guard let data = self.data(using: String.Encoding.utf8) else {
            return nil
        }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { (unsafeBytes) -> Void in
            CC_MD5(unsafeBytes, CC_LONG(data.count), &digest)
        }
        let output = digest.reduce("", {$0 + String(format: "%02x", $1)})
        return output
    }

}
