
#import <Foundation/Foundation.h>

@protocol PHTagViewDelegate <NSObject>
- (void)tagAcknowledgementWasSubmitted;
- (void)tagAcknowledgementDidSucceed:(NSString *)tagID;
- (void)tagAcknowledgementDidFail;
@end
