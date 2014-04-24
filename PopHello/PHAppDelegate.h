
#import <UIKit/UIKit.h>
#import "PHServiceAvailabilityDelegate.h"
#import "PHTagCreateDelegate.h"
#import "PHTagViewDelegate.h"
#import "PHZoneManagerDelegate.h"

@interface PHAppDelegate : UIResponder <
    UIApplicationDelegate,
    PHTagCreateDelegate,
    PHTagViewDelegate,
    PHZoneManagerDelegate,
    PHServiceAvailabilityDelegate>
@property (strong, nonatomic) UIWindow *window;
@end
