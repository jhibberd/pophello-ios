
#import <Foundation/Foundation.h>
#import "PHStoreManager.h"

@interface PHTagsStore : NSObject
- (id)initWithStoreManager:(PHStoreManager *)storeManager;
- (void)put:(NSArray *)tags;
- (NSDictionary *)fetch:(NSString *)tagId;
- (NSArray *)fetchAll;
- (void)clear;
@end
