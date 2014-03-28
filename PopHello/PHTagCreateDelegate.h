
#import <Foundation/Foundation.h>

@protocol PHTagCreateDelegate <NSObject>
- (void)tagCreateDidSucceed;
- (void)tagCreateDidFail;
@end
