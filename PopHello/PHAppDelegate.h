
#import <UIKit/UIKit.h>
#import "PHServiceAvailabilityDelegate.h"
#import "PHZoneManagerDelegate.h"
#import "PopHello-Swift.h"

@interface PHAppDelegate : UIResponder <
    UIApplicationDelegate,
    TagCreateViewDelegate,
    TagViewDelegate,
    PHZoneManagerDelegate,
    PHServiceAvailabilityDelegate>
@property (strong, nonatomic) UIWindow *window;
@end
