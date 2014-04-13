
#import <UIKit/UIKit.h>
#import "PHAnimationViewDelegate.h"
#import "PHServer.h"
#import "PHTagCreateDelegate.h"
#import "PHZoneManager.h"

@interface PHMainViewController : UIViewController <UIGestureRecognizerDelegate, PHAnimationViewDelegate>
- (void)presentTagView:(NSDictionary *)tag;
- (void)presentTagCreate:(PHZoneManager *)zoneManager
                  server:(PHServer *)server
                delegate:(id<PHTagCreateDelegate>)delegate;
- (void)presentTagCreationSuccess;
- (void)presentTagCreationFailure;
- (void)presentPending;
- (void)presentServiceUnavailable:(NSString *)reason;
- (void)presentNothing;
@end
