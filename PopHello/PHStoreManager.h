
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import "PHServiceAvailabilityMonitor.h"

@interface PHStoreManager : NSObject
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
- (id)initWithServiceAvailabilityMonitor:(PHServiceAvailabilityMonitor *)serviceAvailabilityMonitor;
- (void)saveContext;
@end
