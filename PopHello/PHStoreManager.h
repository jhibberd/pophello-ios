
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@interface PHStoreManager : NSObject
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
- (void)saveContext;
@end
