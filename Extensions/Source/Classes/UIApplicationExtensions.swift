import Foundation

// MARK: - UIApplicationExtension
extension UIApplication {

    static let bundleIdentifier: String = {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("\(self.className) - \(#function): can't read bundle identifier from bundle: \(Bundle.main).")
        }
        return bundleIdentifier
    }()

}
