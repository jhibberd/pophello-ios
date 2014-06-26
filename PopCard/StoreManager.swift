import CoreData

// Manage access to the Core Data Managed Object Context for persisting objects locally on the device.
//
// This code is largely based on the auto-generated code provided by XCode when creating a project with Core Data
// enabled.
//
class StoreManager {
    
    var managedObjectContext: NSManagedObjectContext?
    var managedObjectModel: NSManagedObjectModel?
    var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    let serviceAvailabilityMonitor: ServiceAvailabilityMonitor
    
    init(serviceAvailabilityMonitor: ServiceAvailabilityMonitor) {
        self.serviceAvailabilityMonitor = serviceAvailabilityMonitor
    }
    
    func saveContext() {
        var error: NSError?
        let context = getManagedObjectContext()
        if context.hasChanges && !context.save(&error) {
            serviceAvailabilityMonitor.localStorageDidFail(error!)
        }
    }
    
    func getManagedObjectContext() -> NSManagedObjectContext {
        if let context = managedObjectContext {
            return context
        }
        let coordinator = getPersistentStoreCoordinator()
        assert(coordinator, "Failed to get NSPersistentStoreCoordinator")
        managedObjectContext = NSManagedObjectContext()
        managedObjectContext!.persistentStoreCoordinator = coordinator!
        return managedObjectContext!
    }
    
    func getManagedObjectModel() -> NSManagedObjectModel {
        if let model = managedObjectModel {
            return model
        }
        let modelURL = NSBundle.mainBundle().URLForResource("PopCard", withExtension: "momd")
        managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)
        return managedObjectModel!
    }
    
    func getPersistentStoreCoordinator() -> NSPersistentStoreCoordinator? {
        if let coordinator = persistentStoreCoordinator {
            return coordinator
        }
        let storeURL = getApplicationDocumentsDirectory().URLByAppendingPathComponent("PopCard.sqlite")
        var error: NSError?
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: getManagedObjectModel())
        let store = persistentStoreCoordinator?.addPersistentStoreWithType(
            NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error)
        if !store {
            serviceAvailabilityMonitor.localStorageDidFail(error!)
            return nil
        }
        return persistentStoreCoordinator
    }
    
    func getApplicationDocumentsDirectory() -> NSURL {
        return NSFileManager.defaultManager().URLsForDirectory(
            .DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
    }
}