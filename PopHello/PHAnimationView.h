
#import <UIKit/UIKit.h>
#import "PHAnimationViewDelegate.h"

@interface PHAnimationView : UIView
@property (nonatomic, weak) id<PHAnimationViewDelegate> delegate;
- (void)presentView:(UIView *)view identifier:(NSString *)identifier;
- (void)presentNothingImmediately;
@end
