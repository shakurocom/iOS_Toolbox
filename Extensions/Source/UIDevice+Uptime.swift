//
//
//

import UIKit

extension UIDevice {

    internal static func uptime() -> TimeInterval {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.stride
        sysctlbyname("kern.boottime", &boottime, &size, nil, 0)
        var now = time_t()
        time(&now)
        return boottime.tv_sec > 0 ? TimeInterval(now - boottime.tv_sec) : 0
    }

}
