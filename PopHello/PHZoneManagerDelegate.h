
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "PHZoneServiceRequirement.h"

@protocol PHZoneManagerDelegate <NSObject>
- (void)didEnterTagRegion:(NSDictionary *)tag;
- (void)didExitTagRegion:(NSDictionary *)tag;
- (void)zoneServiceDidBecomeAvailable;
- (void)zoneServiceDidBecomeUnavailable:(PHZoneServiceRequirement)missing;
@end
