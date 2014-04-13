
#import <Foundation/Foundation.h>

@protocol PHServiceAvailabilityDelegate <NSObject>
- (void)serviceDidBecomeAvailable;
- (void)serviceDidBecomeUnavailable;
@end
