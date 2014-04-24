
#import <Foundation/Foundation.h>
#import "PHStoreManager.h"

@interface PHTagActiveStore : NSObject
- (id)initWithStoreManager:(PHStoreManager *)storeManager;
- (void)put:(NSDictionary *)tag;
- (NSDictionary *)fetch;
- (void)clearIfActive:(NSString *)tagID;
- (void)clear;
@end
