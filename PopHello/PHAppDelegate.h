
#import <UIKit/UIKit.h>
#import "PHServiceAvailabilityDelegate.h"
#import "PHTagCreateDelegate.h"
#import "PHZoneManagerDelegate.h"

@interface PHAppDelegate : UIResponder
    <UIApplicationDelegate, PHTagCreateDelegate, PHZoneManagerDelegate, PHServiceAvailabilityDelegate>
@property (strong, nonatomic) UIWindow *window;
@end
