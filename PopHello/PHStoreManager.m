
#import "PHStoreManager.h"

// Manage access to the Core Data Managed Object Context for persisting objects locally on the device.
//
// This code is largely based on the auto-generated code provided by XCode when creating a project with Core Data
// enabled.
//
@implementation PHStoreManager {
    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    PHServiceAvailabilityMonitor *_serviceAvailabilityMonitor;
}

- (id)initWithServiceAvailabilityMonitor:(PHServiceAvailabilityMonitor *)serviceAvailabilityMonitor
{
    self = [super init];
    if (self) {
        _serviceAvailabilityMonitor = serviceAvailabilityMonitor;
    }
    return self;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            [_serviceAvailabilityMonitor localStorageDidFail:error];
        }
    }
}

// Returns the managed object context for the application.
//
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the
// application.
//
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
//
// If the model doesn't already exist, it is created from the application's model.
//
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PopHello" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
//
// If the coordinator doesn't already exist, it is created and the application's store added to it.
//
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PopHello.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                   initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:nil
                                                           error:&error]) {
        [_serviceAvailabilityMonitor localStorageDidFail:error];
        return nil;
    }
    return _persistentStoreCoordinator;
}

// Returns the URL to the application's Documents directory.
//
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

@end
