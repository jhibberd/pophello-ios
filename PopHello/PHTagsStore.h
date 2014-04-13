
#import <Foundation/Foundation.h>
#import "PHServiceAvailabilityMonitor.h"
#import "PHStoreManager.h"

@interface PHTagsStore : NSObject
- (id)initWithStoreManager:(PHStoreManager *)storeManager
    serviceAvailabilityMonitor:(PHServiceAvailabilityMonitor *)serviceAvailabilityMonitor;
- (void)put:(NSArray *)tags;
- (NSDictionary *)fetch:(NSString *)tagId;
- (NSArray *)fetchAll;
- (void)clear;
@end
