
#import "MWLogging.h"
#import "PHTagsStore.h"

static NSString *const kPHEntity = @"Tag";

// Local persistence of nearby tags.
//
@implementation PHTagsStore {
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

// Put a new set of tags into local storage.
//
// This should only be called if there are currently no tags in local storage.
//
- (void)put:(NSArray *)tags
{
    for (NSDictionary *tag in tags) {
        NSManagedObject *object = [NSEntityDescription
                                   insertNewObjectForEntityForName:kPHEntity
                                   inManagedObjectContext:_storeManager.managedObjectContext];
        [object setValue:tag[@"id"] forKey:@"id"];
        [object setValue:tag[@"lat"] forKey:@"lat"];
        [object setValue:tag[@"lng"] forKey:@"lng"];
        [object setValue:tag[@"text"] forKey:@"text"];
        [object setValue:tag[@"user_id"] forKey:@"user_id"];
        [object setValue:tag[@"user_image_url"] forKey:@"user_image_url"];
    }
    [_storeManager saveContext];
}

// Return a tag by ID, or nil if it doesn't exist.
//
// I believe Core Data implements managed object caching so it isn't necessary to implement our own and this call
// should actually read from disk.
//
- (NSDictionary *)fetch:(NSString *)tagID
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:kPHEntity
                                              inManagedObjectContext:_storeManager.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", tagID];
    [fetchRequest setPredicate:predicate];
    NSError *error;
    NSArray *fetchedObjects = [_storeManager.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        MWLogError(@"%@", [error localizedDescription]);
        return nil;
    }
    if ([fetchedObjects count] == 0) {
        return nil;
    }
    return [self makeTagFromManagedObject:[fetchedObjects lastObject]];
}

// Return all stored tags.
//
- (NSArray *)fetchAll
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
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSManagedObject *object in fetchedObjects) {
        NSDictionary *tag = [self makeTagFromManagedObject:object];
        [result addObject:tag];
    }
    return result;
}

// Remove a specific tag from the store.
//
- (void)remove:(NSString *)tagID
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:kPHEntity
                                              inManagedObjectContext:_storeManager.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", tagID];
    [fetchRequest setPredicate:predicate];
    NSError *error;
    NSArray *fetchedObjects = [_storeManager.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        MWLogError(@"%@", [error localizedDescription]);
        return;
    }
    if ([fetchedObjects count] != 1) {
        MWLogError(@"Attempted to delete Tag object not in TagsStore");
        return;
    }
    [_storeManager.managedObjectContext deleteObject:[fetchedObjects lastObject]];
    [_storeManager saveContext];
}

// Remove all tags from local storage.
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
    [_storeManager saveContext];
}

// Make a native tag object from a managed object.
//
// This feels more natural than using a managed class which is then conceptually tied to the fact that it's persisted
// using Core Data.
//
- (NSDictionary *)makeTagFromManagedObject:(NSManagedObject *)object
{
    return @{@"id": (NSString *) [object valueForKey:@"id"],
             @"lat": (NSNumber *) [object valueForKey:@"lat"],
             @"lng": (NSNumber *) [object valueForKey:@"lng"],
             @"text": (NSString *) [object valueForKey:@"text"],
             @"user_id": (NSString *) [object valueForKey:@"user_id"],
             @"user_image_url": (NSString *) [object valueForKey:@"user_image_url"]};
}

@end
