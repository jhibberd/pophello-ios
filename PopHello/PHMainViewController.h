
#import <UIKit/UIKit.h>
#import "PHServer.h"
#import "PHTagCreateDelegate.h"
#import "PHZoneManager.h"

@interface PHMainViewController : UIViewController <UIGestureRecognizerDelegate>
- (void)presentTagView:(NSDictionary *)tag;
- (void)presentTagCreate:(PHZoneManager *)zoneManager
                  server:(PHServer *)server
                delegate:(id<PHTagCreateDelegate>)delegate;
- (void)presentTagCreateSuccess;
- (void)presentTagCreateFailure;
- (void)presentNothing;
@end
