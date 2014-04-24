
#import <Foundation/Foundation.h>
#import "PHStoreManager.h"

@interface PHTagsStore : NSObject
- (id)initWithStoreManager:(PHStoreManager *)storeManager;
- (void)put:(NSArray *)tags;
- (NSDictionary *)fetch:(NSString *)tagID;
- (NSArray *)fetchAll;
- (void)remove:(NSString *)tagID;
- (void)clear;
@end
