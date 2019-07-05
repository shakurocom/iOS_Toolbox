//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import CoreData

public class PoliteCoreStorage {

    public enum PCError: Int, Error {

        case internalInconsistency = 100

        func errorDescription() -> String {
            switch self {
            case .internalInconsistency:
                return NSLocalizedString("The operation could not be completed. Internal inconsistency.", comment: "Storage Error description")
            }
        }

    }

    public struct Configuration {
        let modelName: String
        init(modelName: String) {
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

    class func setupStack(configuration: Configuration, removeDBOnSetupFailed: Bool) throws -> PoliteCoreStorage {
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

    func resetMainQueueContext() {
        mainQueueContext.performAndWait { () -> Void in
            self.mainQueueContext.reset()
        }
    }

    func resetRootSavingContext() {
        rootSavingContext.performAndWait { () -> Void in
            self.rootSavingContext.reset()
        }
    }

}

// MARK: - Public

// MARK: Save/Create

public extension PoliteCoreStorage {

    func saveWithBlock(_ block: @escaping (_ context: NSManagedObjectContext) -> Void, completion: @escaping ((_ error: Error?) -> Void)) {
        saveContext(rootSavingContext, resetAfterSaving: true, changesBlock: block, completion: completion)
    }

    func saveWithBlockAndWait(_ block: @escaping (_ context: NSManagedObjectContext) -> Void) throws {
        try saveContextAndWait(rootSavingContext, resetAfterSaving: true, changesBlock: block)
    }

    func findFirstOrCreate<T: NSManagedObject>(_ entityType: T.Type, withPredicate predicate: NSPredicate, inContext context: NSManagedObjectContext) -> T {
        if let object: T = findFirst(entityType, withPredicate: predicate, inContext: context) {
            return object
        }
        return createEntityInContext(entityType, context: context)
    }
}

// MARK: Main Queue

public extension PoliteCoreStorage {

    func existingObjectWithIDInMainQueueContext<T: NSManagedObject>(_ objectID: NSManagedObjectID) -> T? {
        return existingObjectWithID(objectID, inContext: mainQueueContext)
    }

    func findFirstInMainQueueContext<T: NSManagedObject>(_ entityType: T.Type,
                                                         withPredicate predicate: NSPredicate) -> T? {
        return findFirst(entityType, withPredicate: predicate, inContext: mainQueueContext)
    }

    func findAllInMainQueueContext<T: NSManagedObject>(_ entityType: T.Type,
                                                       sortTerm: [(sortKey: String, ascending: Bool)] = [],
                                                       predicate: NSPredicate? = nil) -> [T]? {
        return findAll(entityType, inContext: mainQueueContext, sortTerm: sortTerm, predicate: predicate)
    }

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

    func countForEntityInMainQueueContext<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) -> Int {
        return countForEntity(entityType, inContext: mainQueueContext, predicate: predicate)
    }
}

// MARK: General

public extension PoliteCoreStorage {

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

    func findFirst<T: NSManagedObject>(_ entityType: T.Type, withPredicate predicate: NSPredicate, inContext context: NSManagedObjectContext) -> T? {
        let request = requestWithEntityType(entityType, predicate: predicate)
        request.fetchLimit = 1
        return executeFetchRequest(request, inContext: context).first
    }

    func findAll<T: NSManagedObject>(_ entityType: T.Type,
                                     inContext context: NSManagedObjectContext,
                                     sortTerm: [(sortKey: String, ascending: Bool)] = [],
                                     predicate: NSPredicate? = nil) -> [T]? {
        let request = requestWithEntityType(entityType, sortTerm: sortTerm, predicate: predicate)
        return executeFetchRequest(request, inContext: context)
    }

    func countForEntity<T: NSManagedObject>(_ entityType: T.Type, inContext context: NSManagedObjectContext, predicate: NSPredicate? = nil) -> Int {
        let request = requestWithEntityType(entityType, predicate: predicate)
        request.resultType = .managedObjectIDResultType
        return countForFetchRequest(request, inContext: context)
    }

    func obtainPermanentIDsForObject<T: NSManagedObject>(_ object: T) {
        guard let context = object.managedObjectContext, object.objectID.isTemporaryID else {
            return
        }
        assert(context !== mainQueueContext || Thread.current.isMainThread, "Access to mainQueueContext in BG thread")
        do {
            try context.obtainPermanentIDs(for: [object])
        } catch {
            //do nothing
        }
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
        let className = String(describing: entityType)
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
