#import <UIKit/UIKit.h>
#import "PHAnimationViewDelegate.h"
#import "PopHello-Swift.h"

@interface PHMainViewController : UIViewController <UIGestureRecognizerDelegate, PHAnimationViewDelegate>
- (void)presentTagView:(Tag *)tag
                server:(Server *)server
              delegate:(id<TagViewDelegate>)delegate;
- (void)presentTagCreate:(ZoneManager *)zoneManager
                  server:(Server *)server
                delegate:(id<TagCreateViewDelegate>)delegate;
- (void)presentTagCreationSuccess;
- (void)presentServerError;
- (void)presentPending;
- (void)presentServiceUnavailable:(NSString *)reason;
- (void)presentNothing;
@end
