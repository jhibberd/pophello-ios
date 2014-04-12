
#import <Foundation/Foundation.h>

@interface NSArray (PHArray)
- (BOOL)containsTagId:(NSString *)tagId;
- (NSArray *)subarrayOfTagsNotIn:(NSArray *)tagArray;
@end
