//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

/**
 Token for observation. You should keep it, otherwise observation will be invalidated.
 */
public class EventHandlerToken {

    private weak var handler: EventHandlerProtocol?
    internal let token: UInt

    internal init(token: UInt, handler: EventHandlerProtocol) {
        self.handler = handler
        self.token = token
    }

    deinit {
        invalidate()
    }

    public func invalidate() {
        handler?.removeToken(token)
        handler = nil
    }

}

/**
 A helper structure if you need old + new values in your notification.
 */
public struct EventHandlerValueChange<T> {

    public let oldValue: T
    public let newValue: T

    public init(oldValue: T, newValue: T) {
        self.oldValue = oldValue
        self.newValue = newValue
    }

}

internal protocol EventHandlerProtocol: class {
    func removeToken(_ token: UInt)
}

/**
 Typed alternative for Foundation.Notification
 'add(handler:)' & 'removeHandler(token:)' intended to be called in pair.
 Please keep token to be able to remove associated handler later.

 - warning:
 Number of tokens is limited by `UInt.max()`
 */
public class EventHandler<T>: EventHandlerProtocol {

    public typealias HandlerType = (_ arg1: T) -> Void

    private struct HandlerData {
        internal let queue: DispatchQueue?
        internal let handler: HandlerType
    }

    private var handlers: [UInt: HandlerData] = [:]
    private var tokenGenerator: UInt = 0
    private let accessLock: NSLock = NSLock()

    public init(name: String? = nil) {
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
    public func add(queue: DispatchQueue? = nil, handler: @escaping HandlerType) -> EventHandlerToken {
        let token = accessLock.execute({ () -> EventHandlerToken in
            tokenGenerator += 1
            let token = EventHandlerToken(token: tokenGenerator, handler: self)
            handlers[token.token] = HandlerData(queue: queue, handler: handler)
            return token
        })
        return token
    }

    /**
     This must be called by **OWNER only!**
     */
    public func invoke(_ arg: T) {
        for (_, value) in handlers {
            if let realQueue = value.queue {
                realQueue.async(execute: { value.handler(arg) })
            } else {
                value.handler(arg)
            }
        }
    }

    internal func removeToken(_ token: UInt) {
        _ = accessLock.execute({
            handlers.removeValue(forKey: token)
        })
    }

}
