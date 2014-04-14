
#import "MWLogging.h"
#import "PHTagActiveStore.h"

static NSString *const kPHEntity = @"TagActive";

@implementation PHTagActiveStore {
    PHStoreManager *_storeManager;
}

- (id)initWithStoreManager:(PHStoreManager *)storeManager
{
    self = [super init];
    if (self) {
        _storeManager = storeManager;
    }
    return self;
}

// Put a tag into local storage as the current active tag, replacing any existing active tag.
//
- (void)put:(NSDictionary *)tag
{
    [self clear];
    
    NSManagedObject *object = [NSEntityDescription
                               insertNewObjectForEntityForName:kPHEntity
                               inManagedObjectContext:_storeManager.managedObjectContext];
    [object setValue:tag[@"id"] forKey:@"id"];
    [object setValue:tag[@"lat"] forKey:@"lat"];
    [object setValue:tag[@"lng"] forKey:@"lng"];
    [object setValue:tag[@"text"] forKey:@"text"];
    
    NSError *error;
    if (![_storeManager.managedObjectContext save:&error]) {
        MWLogError(@"%@", [error localizedDescription]);
    }
}

// Fetch the active tag from local storage, or nil if there is no active tag.
//
// Core Data works best with lists of managed objects. Even though there will only ever be one active tag it's more
// convenient to treat it as a list of one.
//
- (NSDictionary *)fetch
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:kPHEntity
                                              inManagedObjectContext:_storeManager.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *fetchedObjects = [_storeManager.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        MWLogError(@"%@", [error localizedDescription]);
        return nil;
    }
    if ([fetchedObjects count] == 0) {
        return nil;
    }
    NSManagedObject *object = [fetchedObjects lastObject];
    return @{@"id": (NSString *) [object valueForKey:@"id"],
             @"lat": (NSNumber *) [object valueForKey:@"lat"],
             @"lng": (NSNumber *) [object valueForKey:@"lng"],
             @"text": (NSString *) [object valueForKey:@"text"]};
}

// Clear the active tag from local storage only if it matches the passed tag.
//
// This handles the situation when the device exits a tag geofence but, due to overlapping geofences, this may not
// represent the active tag.
//
- (void)clearIfActive:(NSDictionary *)tag
{
    NSDictionary *tagActive = [self fetch];
    // this shouldn't happen because to exit a tag the device must have entered it first
    if (tagActive == nil) {
        MWLogWarning(@"Attempt to clear the active data from local storage, but none exists");
        return;
    }
    if ([tagActive[@"id"] isEqualToString:tag[@"id"]]) {
        [self clear];
    }
}

// Clear the active tag from local storage.
//
// Core Data works best with lists of managed objects. Even though there will only ever be one active tag it's more
// convenient to treat it as a list of one.
//
- (void)clear
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:kPHEntity
                                              inManagedObjectContext:_storeManager.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesPropertyValues:NO]; // more efficient
    NSError *error;
    NSArray *fetchedObjects = [_storeManager.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        MWLogError(@"%@", [error localizedDescription]);
        return;
    }
    for (NSManagedObject *object in fetchedObjects) {
        [_storeManager.managedObjectContext deleteObject:object];
    }
}

@end
