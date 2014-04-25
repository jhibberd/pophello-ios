
#import <UIKit/UIKit.h>
#import "PHServer.h"
#import "PHTagCreateDelegate.h"
#import "PHZoneManager.h"

@interface PHTagCreate : UIView
- (id)initWithZoneManager:(PHZoneManager *)zoneManager
                   server:(PHServer *)server
                 delegate:(id<PHTagCreateDelegate>)delegate;
@end
