
#import <Foundation/Foundation.h>
#import "PHServiceAvailabilityMonitor.h"
#import "PHStoreManager.h"

@interface PHTagActiveStore : NSObject
- (id)initWithStoreManager:(PHStoreManager *)storeManager
    serviceAvailabilityMonitor:(PHServiceAvailabilityMonitor *)serviceAvailabilityMonitor;
- (void)put:(NSDictionary *)tag;
- (NSDictionary *)fetch;
- (void)clearIfActive:(NSDictionary *)tag;
- (void)clear;
@end
