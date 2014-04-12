
#import "NSArray+PHArray.h"

@implementation NSArray (PHArray)

// Return whether an array of tags contains a tag with a specific ID.
//
- (BOOL)containsTagId:(NSString *)tagId
{
    return [self indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [((NSDictionary *)obj)[@"id"] isEqualToString:tagId];
    }] != NSNotFound;
}

// Return a subarray of tags in the array that are not also in a second array.
//
- (NSArray *)subarrayOfTagsNotIn:(NSArray *)tagArray
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return ![tagArray containsTagId:((NSDictionary *)evaluatedObject)[@"id"]];
    }];
    return [self filteredArrayUsingPredicate:predicate];
}

@end
