//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import CoreData

/// The main object that manages Core Data stack and encapsulates helper methods for interaction with Core Data objects

public class PoliteCoreStorage {

    public enum PCError: Int, Error {

        case internalInconsistency = 100

        public func errorDescription() -> String {
            switch self {
            case .internalInconsistency:
                return NSLocalizedString("The operation could not be completed. Internal inconsistency.", comment: "Storage Error description")
            }
        }

    }

    /// Encapsulates initial setup parameters
    /// - Tag: PoliteCoreStorage.Configuration
    public struct Configuration {

        /// The name of .xcdatamodeld file
        public let modelName: String

        /// Initializes Configuration
        ///
        /// - Parameter modelName: The name of .xcdatamodeld file
        public init(modelName: String) {
            self.modelName = modelName
        }
    }

    private enum Constant {
        static let defaultRootDirectoryPrefix = "politeCoreStorage"
        static let defaultBatchSize: Int = 100
    }

    private let rootSavingContext: NSManagedObjectContext!
    private let concurrentFetchContext: NSManagedObjectContext!
    private let mainQueueContext: NSManagedObjectContext!
    private let persistentStoreCoordinatorMain: NSPersistentStoreCoordinator!
    private let persistentStoreCoordinatorWorker: NSPersistentStoreCoordinator!
    private let classToEntityNameMap: [String: String]!
    private let callbackQueue: DispatchQueue

    private init(modelName: String) {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
            else {
                fatalError("Could not initialize database object model")
        }
        callbackQueue = DispatchQueue(label: "politeCoreStorage.callbackQueue.queue", attributes: [])

        let entitiesByName = model.entitiesByName
        var entitiesMap: [String: String] = [String: String]()
        for (name, entity) in entitiesByName {
            entitiesMap[entity.managedObjectClassName] = name
        }
        classToEntityNameMap = entitiesMap
        persistentStoreCoordinatorMain = NSPersistentStoreCoordinator(managedObjectModel: model)
        persistentStoreCoordinatorWorker = NSPersistentStoreCoordinator(managedObjectModel: model)
        rootSavingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        concurrentFetchContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        mainQueueContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    }

    deinit {
        removeObservers()
    }

    // MARK: - Setup

    /// Creates PoliteCoreStorage instance, according to given configuration
    ///
    /// - Parameters:
    ///   - configuration: The instance of [Configuration](x-source-tag://PoliteCoreStorage.Configuration) to use during setup
    ///   - removeDBOnSetupFailed: Pass true to remove DB files and recreate from scratch in case of setup failed
    /// - Returns: The new PoliteCoreStorage instance
    public class func setupStack(configuration: Configuration, removeDBOnSetupFailed: Bool) throws -> PoliteCoreStorage {
        let storage: PoliteCoreStorage = PoliteCoreStorage(modelName: configuration.modelName)
        do {
            try storage.setupCoreDataStack(removeOldDB: false, modelName: configuration.modelName)
        } catch let error {
            if removeDBOnSetupFailed {
                try storage.setupCoreDataStack(removeOldDB: true, modelName: configuration.modelName)
            } else {
                throw error
            }
        }
        return storage
    }

    // MARK: - Maintenance

    /// Calls reset() on main queue context
    public func resetMainQueueContext() {
        mainQueueContext.performAndWait { () -> Void in
            self.mainQueueContext.reset()
        }
    }

    /// Calls reset() on private queue rootSavingContext
    public func resetRootSavingContext() {
        rootSavingContext.performAndWait { () -> Void in
            self.rootSavingContext.reset()
        }
    }

}

// MARK: - Public

// MARK: Save/Create

public extension PoliteCoreStorage {

    /// Performs block on private queue of saving context.
    ///
    /// - Parameters:
    ///   - block: A closure that takes a context as a parameter. Will be executed on private context queue. Caller could apply any changes to DB in it. At the end of execution context will be saved.
    ///   - completion: A closure that takes a saving error as a parameter. Will be performed after saving context.
    /// - Tag: saveWithBlock
    func saveWithBlock(_ block: @escaping (_ context: NSManagedObjectContext) -> Void, completion: @escaping ((_ error: Error?) -> Void)) {
        saveContext(rootSavingContext, resetAfterSaving: true, changesBlock: block, completion: completion)
    }

    /// Synchronous variant of [saveWithBlock](x-source-tag://saveWithBlock)
    /// - Tag: saveWithBlockAndWait
    func saveWithBlockAndWait(_ block: @escaping (_ context: NSManagedObjectContext) -> Void) throws {
        try saveContextAndWait(rootSavingContext, resetAfterSaving: true, changesBlock: block)
    }

    /// Finds first entity that matches predicate, or creates new one if no entity found
    /// See also: [findFirstByIdOrCreate](x-source-tag://findFirstByIdOrCreate)
    ///
    /// - Parameters:
    ///   - entityType: A type of entity to find
    ///   - predicate: NSPredicate object that describes entity
    ///   - context:  NSManagedObjectContext where entity should be find
    /// - Returns: First found or created entity, never returns nil
    /// - Tag: findFirstOrCreate
    func findFirstOrCreate<T: NSManagedObject>(_ entityType: T.Type, withPredicate predicate: NSPredicate, inContext context: NSManagedObjectContext) -> T {
        if let object: T = findFirst(entityType, withPredicate: predicate, inContext: context) {
            return object
        }
        return createEntityInContext(entityType, context: context)
    }
}

// MARK: Main Queue

public extension PoliteCoreStorage {

    /// Returns an entity for the specified objectID or nil if the object does not exist.
    /// See also [existingObjectWithID](x-source-tag://existingObjectWithID)
    ///
    /// - Parameter objectID: The NSManagedObjectID for the specified entity
    /// - Returns: An entity for the specified objectID or nil
    /// - Warning: To use on main queue only!
    func existingObjectWithIDInMainQueueContext<T: NSManagedObject>(_ objectID: NSManagedObjectID) -> T? {
        return existingObjectWithID(objectID, inContext: mainQueueContext)
    }

    /// Returns an entity for the specified predicate or nil if the object does not exist.
    /// See also [findFirst](x-source-tag://findFirst)
    ///
    /// - Parameters:
    ///   - entityType: A type of entity to find
    ///   - predicate: NSPredicate object that describes entity
    /// - Returns: First found entity or nil
    /// - Warning: To use on main queue only!
    func findFirstInMainQueueContext<T: NSManagedObject>(_ entityType: T.Type,
                                                         withPredicate predicate: NSPredicate) -> T? {
        return findFirst(entityType, withPredicate: predicate, inContext: mainQueueContext)
    }

    /// Finds all entities with given type. Optionally filterred by predicate
    /// See also [findAll](x-source-tag://findAll)
    ///
    /// - Parameters:
    ///   - entityType: A type of entity to find
    ///   - sortTerm: An array of sort keys
    ///   - predicate: predicate to filter by
    /// - Returns: Array of entities
    /// - Warning: To use on main queue only!
    func findAllInMainQueueContext<T: NSManagedObject>(_ entityType: T.Type,
                                                       sortTerm: [(sortKey: String, ascending: Bool)] = [],
                                                       predicate: NSPredicate? = nil) -> [T]? {
        return findAll(entityType, inContext: mainQueueContext, sortTerm: sortTerm, predicate: predicate)
    }

    /// Returns new NSFetchedResultsController for using in main queue.
    ///
    /// - Parameters:
    ///   - entityType: A type of entity to fetch
    ///   - sortTerm: An array of sort keys
    ///   - predicate: predicate to filter by
    ///   - sectionNameKeyPath: Key path to group by, pass nil to indicate that the controller should generate a single section.
    ///   - cacheName: The name of the cache file the receiver should use. Pass nil to prevent caching.
    ///   - configureRequest: A closure that takes a NSFetchRequest as a parameter, can be used to customize the request.
    /// - Returns: A NSFetchedResultsController instance
    /// - Warning: To use on main queue only!
    func mainQueueFetchedResultsController<T: NSManagedObject>(_ entityType: T.Type,
                                                               sortTerm: [(sortKey: String, ascending: Bool)],
                                                               predicate: NSPredicate? = nil,
                                                               sectionNameKeyPath: String? = nil,
                                                               cacheName: String? = nil,
                                                               configureRequest: ((_ request: NSFetchRequest<T>) -> Void)?) -> NSFetchedResultsController<T> {

        assert(Thread.current.isMainThread, "Access to mainQueueContext in BG thread")
        let request = requestWithEntityType(entityType, sortTerm: sortTerm, predicate: predicate)
        request.fetchBatchSize = Constant.defaultBatchSize
        request.returnsObjectsAsFaults = false
        request.includesPropertyValues = true
        configureRequest?(request)

        let resultsController: NSFetchedResultsController<T> = NSFetchedResultsController(fetchRequest: request,
                                                                                          managedObjectContext: mainQueueContext,
                                                                                          sectionNameKeyPath: sectionNameKeyPath,
                                                                                          cacheName: cacheName)
        return resultsController
    }

    /// Returns the number of entities according to the given predicate.
    /// See also [countForEntity](x-source-tag://countForEntity)
    ///
    /// - Parameters:
    ///   - entityType: A type of entity to fetch
    ///   - predicate: NSPredicate to filter by
    /// - Returns: Returns the number of entities.
    /// - Warning: To use on main queue only!
    func countForEntityInMainQueueContext<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) -> Int {
        return countForEntity(entityType, inContext: mainQueueContext, predicate: predicate)
    }
}

// MARK: General

public extension PoliteCoreStorage {

    /// Could be used to fetch objects in the background for temporary usage, context will be resete directly after "block:" execution
    ///
    /// - Parameters:
    ///   - block: A closure that takes a context as a parameter.
    ///   - waitUntilFinished: block or do not block current thread
    /// - Tag: fetchWithBlock
    func fetchWithBlock(_ block: @escaping ((_ context: NSManagedObjectContext) -> Void), waitUntilFinished: Bool) {
        let fetchContext: NSManagedObjectContext = concurrentFetchContext
        let fetchBlock = { () -> Void in
            block(fetchContext)
            fetchContext.reset()
        }

        if waitUntilFinished {
            fetchContext.performAndWait(fetchBlock)
        } else {
            fetchContext.perform(fetchBlock)
        }
    }

    /// Returns the object for the specified ID or nil if the object does not exist.
    ///
    /// - Parameters:
    ///   - objectID: The Object ID for the requested object.
    ///   - context: The target NSManagedObjectContext
    /// - Returns: The object specified by objectID. If the object cannot be fetched, or does not exist, or cannot be faulted, it returns nil.
    /// - Tag: existingObjectWithID
    func existingObjectWithID<T: NSManagedObject>(_ objectID: NSManagedObjectID, inContext context: NSManagedObjectContext) -> T? {

        assert(context !== mainQueueContext || Thread.current.isMainThread, "Access to mainQueueContext in BG thread")

        var object: T?
        do {
            try object = context.existingObject(with: objectID) as? T
        } catch let error as NSError {
            debugPrint("Existing object with ID does not exist, or cannot be faulted error: \(error)")
            assertionFailure()
        }
        return object
    }

    /// Returns an entity for the specified predicate or nil if the object does not exist.
    ///
    /// - Parameters:
    ///   - entityType: A type of entity to find
    ///   - predicate: NSPredicate object that describes entity
    ///   - context: The target context
    /// - Returns: First found entity or nil
    /// - Tag: findFirst
    func findFirst<T: NSManagedObject>(_ entityType: T.Type, withPredicate predicate: NSPredicate, inContext context: NSManagedObjectContext) -> T? {
        let request = requestWithEntityType(entityType, predicate: predicate)
        request.fetchLimit = 1
        return executeFetchRequest(request, inContext: context).first
    }

    /// Finds all entities with given type. Optionally filterred by predicate
    ///
    /// - Parameters:
    ///   - entityType: A type of entity to find
    ///   - context: The target context
    ///   - sortTerm: An array of sort keys
    ///   - predicate: predicate to filter by
    /// - Returns: Array of entities
    /// - Tag: findAll
    func findAll<T: NSManagedObject>(_ entityType: T.Type,
                                     inContext context: NSManagedObjectContext,
                                     sortTerm: [(sortKey: String, ascending: Bool)] = [],
                                     predicate: NSPredicate? = nil) -> [T]? {
        let request = requestWithEntityType(entityType, sortTerm: sortTerm, predicate: predicate)
        return executeFetchRequest(request, inContext: context)
    }

    /// Returns the number of entities according to the given predicate.
    ///
    /// - Parameters:
    ///   - entityType: A type of entity to fetch
    ///   - context: The target context
    ///   - predicate: NSPredicate to filter by
    /// - Returns: Returns the number of entities.
    /// - Tag: countForEntity
    func countForEntity<T: NSManagedObject>(_ entityType: T.Type, inContext context: NSManagedObjectContext, predicate: NSPredicate? = nil) -> Int {
        let request = requestWithEntityType(entityType, predicate: predicate)
        request.resultType = .managedObjectIDResultType
        return countForFetchRequest(request, inContext: context)
    }
}

// MARK: - Private

private extension PoliteCoreStorage {

    // MARK: Setup

    func setupCoreDataStack(removeOldDB: Bool, modelName: String) throws {
        let storeURL = PoliteCoreStorage.rootStorageDirectoryURL(removeOldDB: removeOldDB, modelName: modelName).appendingPathComponent("\(modelName).sqlite", isDirectory: false)
        let options: [AnyHashable: Any] = [NSMigratePersistentStoresAutomaticallyOption: true,
                                           NSInferMappingModelAutomaticallyOption: true]

        try self.persistentStoreCoordinatorMain.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        try self.persistentStoreCoordinatorWorker.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)

        // Setup context

        self.rootSavingContext.mergePolicy = NSOverwriteMergePolicy
        self.rootSavingContext.undoManager = nil
        self.rootSavingContext.persistentStoreCoordinator = self.persistentStoreCoordinatorWorker

        self.concurrentFetchContext.parent = self.rootSavingContext
        self.concurrentFetchContext.undoManager = nil

        self.mainQueueContext.undoManager = nil
        self.mainQueueContext.persistentStoreCoordinator = self.persistentStoreCoordinatorMain

        self.addObservers()
    }

    class func rootStorageDirectoryURL(removeOldDB: Bool, modelName: String) -> URL {
        let fileManager: FileManager =  FileManager.default
        guard let rootDirURL: URL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Can't create root storage directory. .urls(for: .documentDirectory")
        }
        let dirName: String = "\(Constant.defaultRootDirectoryPrefix).\(modelName)"
        var storeDirURL: URL = rootDirURL.appendingPathComponent(dirName, isDirectory: true)
        if removeOldDB {
            try? fileManager.removeItem(at: storeDirURL)
        }
        do {
            try fileManager.createDirectory(at: storeDirURL, withIntermediateDirectories: true, attributes: nil)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try storeDirURL.setResourceValues(resourceValues)
        } catch let error as NSError {
            if error.code != NSFileWriteFileExistsError {
                assertionFailure("Can't create or excluded from backup root storage directory. error:\(error)")
            }
        }
        return storeDirURL
    }

    // MARK: Helpers

    func entityName<T: NSManagedObject>(_ entityType: T.Type) -> String {
        let className = NSStringFromClass(entityType)
        guard let entityName: String = classToEntityNameMap[className] else {
            fatalError("Entity name not found for class name \"\(className)\"")
        }
        return entityName
    }

    func createEntityInContext<T: NSManagedObject>(_ entityType: T.Type, context: NSManagedObjectContext) -> T {
        assert(context !== mainQueueContext || Thread.current.isMainThread, "Access to mainQueueContext in BG thread")
        let name = entityName(entityType)
        guard let entity: T = NSEntityDescription.insertNewObject(forEntityName: name, into: context) as? T else {
            fatalError("\(type(of: self)) - \(#function): . \(name)")
        }
        return  entity
    }

    func requestWithEntityType<T: NSManagedObject>(_ entityType: T.Type,
                                                   sortTerm: [(sortKey: String, ascending: Bool)] = [],
                                                   predicate: NSPredicate? = nil) -> NSFetchRequest<T> {
        let request: NSFetchRequest<T> = NSFetchRequest<T>(entityName: entityName(entityType))
        request.includesPendingChanges = true
        if sortTerm.count > 0 {
            var sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor]()
            for sortKey in sortTerm {
                sortDescriptors.append(NSSortDescriptor(key: sortKey.sortKey, ascending: sortKey.ascending))
            }
            request.sortDescriptors = sortDescriptors
        }

        request.predicate = predicate
        return request
    }

    func executeFetchRequest<T: NSManagedObject>(_ request: NSFetchRequest<T>, inContext context: NSManagedObjectContext) -> [T] {
        assert(context !== mainQueueContext || Thread.current.isMainThread, "Access to mainQueueContext in BG thread")
        var results: [T]?
        do {
            try results = context.fetch(request)
        } catch let error {
            assertionFailure("Can't execute Fetch Request \(error)")
        }
        return results ?? [T]()
    }

    func countForFetchRequest<T: NSManagedObject>(_ request: NSFetchRequest<T>, inContext context: NSManagedObjectContext) -> Int {
        assert(context !== mainQueueContext || Thread.current.isMainThread, "Access to mainQueueContext in BG thread")
        do {
            let result: Int = try context.count(for: request)
            return result
        } catch let error {
            assertionFailure("Can't execute Fetch Request \(error)")
            return 0
        }
    }

    func saveContext(_ context: NSManagedObjectContext,
                     resetAfterSaving: Bool,
                     changesBlock: ((_ context: NSManagedObjectContext) -> Void)? = nil,
                     completion: @escaping ((_ error: Error?) -> Void)) {
        let performCompletionClosure: (_ error: Error?) -> Void = { (error: Error?) -> Void in
            (self.callbackQueue).async(execute: {
                completion(error)
            })
        }
        context.perform {
            context.reset()
            changesBlock?(context)
            guard context.hasChanges else {
                performCompletionClosure(nil)
                return
            }
            do {
                try context.save()
                if resetAfterSaving {
                    context.reset()
                }
                performCompletionClosure(nil)
            } catch let error {
                performCompletionClosure(error)
                assertionFailure("Could not save context \(error)")
            }
        }
    }

    func saveContextAndWait(_ context: NSManagedObjectContext,
                            resetAfterSaving: Bool,
                            changesBlock: ((_ context: NSManagedObjectContext) -> Void)? = nil) throws {
        var saveError: Error?
        context.performAndWait {
            context.reset()
            changesBlock?(context)
            guard context.hasChanges else {
                return
            }
            do {
                try context.save()
                if resetAfterSaving {
                    context.reset()
                }
            } catch let error {
                saveError = error
                assertionFailure("Could not save context \(error)")
            }
        }
        if let  actualError = saveError {
            throw actualError
        }
    }

    // MARK: - Observing

    func addObservers() {
        if rootSavingContext == nil || mainQueueContext == nil {
            return
        }
        removeObservers()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(rootSavingContextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: rootSavingContext)
        notificationCenter.addObserver(self, selector: #selector(contextWillSave(_:)), name: NSNotification.Name.NSManagedObjectContextWillSave, object: rootSavingContext)
        notificationCenter.addObserver(self, selector: #selector(contextWillSave(_:)), name: NSNotification.Name.NSManagedObjectContextWillSave, object: mainQueueContext)
        notificationCenter.addObserver(self, selector: #selector(contextWillSave(_:)), name: NSNotification.Name.NSManagedObjectContextWillSave, object: concurrentFetchContext)
    }

    func removeObservers() {
        if rootSavingContext == nil || mainQueueContext == nil {
            return
        }
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: rootSavingContext)
        notificationCenter.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextWillSave, object: rootSavingContext)
        notificationCenter.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextWillSave, object: mainQueueContext)
        notificationCenter.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextWillSave, object: concurrentFetchContext)
    }

    @objc func rootSavingContextDidSave(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext, context === rootSavingContext else {
            return
        }
        if Thread.isMainThread {
            if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                for object in updatedObjects {
                    do {
                        try mainQueueContext.existingObject(with: object.objectID).willAccessValue(forKey: nil)
                    } catch {
                        //do nothing
                    }
                }
            }
            mainQueueContext.mergeChanges(fromContextDidSave: notification)
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                self.rootSavingContextDidSave(notification)
            })
        }
    }

    @objc func contextWillSave(_ notification: Notification) {
        if let context = notification.object as? NSManagedObjectContext {
            assert(context === rootSavingContext, "Attempt to save the wrong context \(context)")
            if context.insertedObjects.count > 0 {
                do {
                    try context.obtainPermanentIDs(for: Array(context.insertedObjects))
                } catch {
                    //do nothing
                }
            }
        }
    }

}
