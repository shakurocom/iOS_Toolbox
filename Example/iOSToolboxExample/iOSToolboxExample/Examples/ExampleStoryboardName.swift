//
//
//

import UIKit

internal enum ExampleStoryboardName: String {

    case main = "Main"

    internal func storyboard() -> UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: Bundle.main)
    }

}
