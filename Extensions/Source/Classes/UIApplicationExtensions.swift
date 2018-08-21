import Foundation

// MARK: - UIApplicationExtension
extension UIApplication {

    public static let bundleIdentifier: String = {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("\(#file) - \(#function): can't read bundle identifier from bundle: \(Bundle.main).")
        }
        return bundleIdentifier
    }()

}
