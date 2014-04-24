
#import <UIKit/UIKit.h>
#import "PHAnimationViewDelegate.h"
#import "PHServer.h"
#import "PHTagCreateDelegate.h"
#import "PHTagViewDelegate.h"
#import "PHZoneManager.h"

@interface PHMainViewController : UIViewController <UIGestureRecognizerDelegate, PHAnimationViewDelegate>
- (void)presentTagView:(NSDictionary *)tag
                server:(PHServer *)server
              delegate:(id<PHTagViewDelegate>)delegate;
- (void)presentTagCreate:(PHZoneManager *)zoneManager
                  server:(PHServer *)server
                delegate:(id<PHTagCreateDelegate>)delegate;
- (void)presentTagCreationSuccess;
- (void)presentServerError;
- (void)presentPending;
- (void)presentServiceUnavailable:(NSString *)reason;
- (void)presentNothing;
@end
