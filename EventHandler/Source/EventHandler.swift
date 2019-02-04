//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

internal typealias EventHandlerToken = UInt

/**
 A helper structure if you need old + new values in your notification.
 */
internal struct EventHandlerValueChange<T> {
    internal let oldValue: T
    internal let newValue: T
}

/**

 Typed alternative for Foundation.Notification
 'add(handler:)' & 'removeHandler(token:)' intended to be called in pair.
 Please keep token to be able to remove associated handler later.

 - warning:
 Number of tokens is limited by `UInt.max()`
 */
internal class EventHandler<T> {

    typealias HandlerType = (_ arg1: T) -> Void

    private struct HandlerData {
        internal let queue: DispatchQueue?
        internal let handler: HandlerType
    }

    private var handlers: [EventHandlerToken: HandlerData] = [:]
    private var tokenGenerator: EventHandlerToken = 0
    private let accessLock: NSLock = NSLock()

    init(name: String? = nil) {
        if let realName = name {
            accessLock.name = realName + ".accessLock"
        } else {
            accessLock.name = "\(type(of: self)).accessLock"
        }
    }

    /**
     Adds another handler.

     - parameter queue: `handler` will be run on this queue. If `nil`, event invoker's queue will be used directly.
     - parameter handler: block to be called on each invoked event.
     */
    internal func add(queue: DispatchQueue? = nil, handler: @escaping HandlerType) -> EventHandlerToken {
        let token: EventHandlerToken = accessLock.execute({
            tokenGenerator += 1
            handlers[tokenGenerator] = HandlerData(queue: queue, handler: handler)
            return tokenGenerator
        })
        return token
    }

    /**
     Releases handler, associated with provided token.
     Invalid tokens will be ignored.
     */
    internal func removeHandler(token: EventHandlerToken) {
        accessLock.execute({
            handlers.removeValue(forKey: token)
        })
    }

    /**
     This must be called by **OWNER only!**
     */
    internal func invoke(_ arg: T) {
        for (_, value) in handlers {
            if let realQueue = value.queue {
                realQueue.async(execute: { value.handler(arg) })
            } else {
                value.handler(arg)
            }
        }
    }

}
