//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import UIKit

//TODO: add unit tests
/**
 Wrapper for UserDefaults.
 Subclass and add SettingItem<Type> vars to it.

 Concrete setting items assumed to be changed only through their interface.
 If you change value directly in UserDefaults via a key, setting item will not recognize this change and will have old cached value.

 If you want additional logic to be executed when some value is changed - use SettingItem.didChange.add() blocks.
 */
open class Settings {

    private var allItems: [SettingItemBase] = []
    private var willEnterForegroundObserver: NSObjectProtocol?

    // MARK: - Initialization

    public init() {
        allItems = allSettingItems()
        allItems.forEach({ $0.updateFromUserDefaults() })
        if allItems.contains(where: { $0.isChangeableInSettings }) {
            willEnterForegroundObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: nil,
                using: { [weak self] (_) in
                    self?.allItems.lazy
                        .filter({ $0.isChangeableInSettings })
                        .forEach({ $0.updateFromUserDefaults() })
            })
        }
    }

    deinit {
        if let observer = willEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
            willEnterForegroundObserver = nil
        }
    }

    // MARK: - Public

    /**
     Resets all setting items to default values.
     If you override this - you should call super implementation.
     - parameter hard: If `false` - will reset only resetable items. If `true` - will force-reset all items.
     */
    public func reset(hard: Bool) {
        for item in allItems where hard || item.isResetable {
            item.reset()
        }
    }

    // MARK: - Private

    private func allSettingItems() -> [SettingItemBase] {
        // We use Mirror here to obtain all our properties, that are SettingItemBase,
        // because this class will be subclassed.
        let selfMirror = Mirror(reflecting: self)
        let allItems = selfMirror.children.compactMap({ (child: (label: String?, value: Any)) -> SettingItemBase? in
            guard child.label != nil, let realValue = child.value as? SettingItemBase else {
                return nil
            }
            return realValue
        })
        return allItems
    }

}
