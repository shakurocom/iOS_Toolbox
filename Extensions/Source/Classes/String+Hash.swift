import Foundation

// MARK: - SHA512, MD5
extension String {

    func SHA512() -> String? {
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

    func MD5() -> String? {
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
