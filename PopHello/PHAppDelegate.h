
#import <UIKit/UIKit.h>
#import "PHTagCreateDelegate.h"
#import "PHZoneManagerDelegate.h"

@interface PHAppDelegate : UIResponder <UIApplicationDelegate, PHTagCreateDelegate, PHZoneManagerDelegate>
@property (strong, nonatomic) UIWindow *window;
@end
