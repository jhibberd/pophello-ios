
#import <Foundation/Foundation.h>

@protocol PHTagCreateDelegate <NSObject>
- (void)tagCreationWasSubmitted;
- (void)tagCreationDidSucceed;
- (void)tagCreationDidFail;
@end
