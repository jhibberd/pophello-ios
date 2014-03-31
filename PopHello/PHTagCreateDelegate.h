
#import <Foundation/Foundation.h>

@protocol PHTagCreateDelegate <NSObject>
- (void)newTagCreationWasSubmitted;
- (void)newTagCreationDidSucceed;
- (void)newTagCreationDidFail;
@end
