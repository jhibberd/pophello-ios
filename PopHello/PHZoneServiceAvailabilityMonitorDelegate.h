
#import <Foundation/Foundation.h>
#import "PHZoneServiceRequirement.h"

@protocol PHZoneServiceAvailabilityMonitorDelegate <NSObject>
- (void)zoneServiceDidBecomeAvailable;
- (void)zoneServiceDidBecomeUnavailable:(PHZoneServiceRequirement)missing;
@end
