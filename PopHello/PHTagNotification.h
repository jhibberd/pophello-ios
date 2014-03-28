
#import <Foundation/Foundation.h>

@interface PHTagNotification : NSObject
+ (void)present:(NSDictionary *)tag;
+ (void)dismissIfPresenting:(NSDictionary *)tag;
+ (void)dismissAll;
@end
