//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import CommonCryptoModule
import Foundation

extension Data {

    public func MD5() -> String? {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = self.withUnsafeBytes({ bytes in
            CC_MD5(bytes.baseAddress, CC_LONG(self.count), &digest)
        })
        var digestHex = ""
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        return digestHex
    }

}
