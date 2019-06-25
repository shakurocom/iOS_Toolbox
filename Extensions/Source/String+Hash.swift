//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk (updated for swift 5); original found on the Internets
//

import CommonCryptoModule
import Foundation

extension String {

    public func SHA512() -> String? {
        guard let data = self.data(using: String.Encoding.utf8) else {
            return nil
        }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes({ (unsafeBytes: UnsafeRawBufferPointer) -> Void in
            CC_SHA512(unsafeBytes.baseAddress, CC_LONG(data.count), &digest)
        })
        let output = digest.reduce(into: "", { $0.append(contentsOf: String(format: "%02x", $1)) })
        return output
    }

    public func MD5() -> String? {
        guard let data = self.data(using: String.Encoding.utf8) else {
            return nil
        }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes({ (unsafeBytes: UnsafeRawBufferPointer) -> Void in
            CC_MD5(unsafeBytes.baseAddress, CC_LONG(data.count), &digest)
        })
        let output = digest.reduce(into: "", { $0.append(contentsOf: String(format: "%02x", $1)) })
        return output
    }

}
