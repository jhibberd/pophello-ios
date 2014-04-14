
#import <Foundation/Foundation.h>
#import "PHStoreManager.h"

@interface PHTagActiveStore : NSObject
- (id)initWithStoreManager:(PHStoreManager *)storeManager;
- (void)put:(NSDictionary *)tag;
- (NSDictionary *)fetch;
- (void)clearIfActive:(NSDictionary *)tag;
- (void)clear;
@end
