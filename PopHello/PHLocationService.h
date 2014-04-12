
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "PHLocationServiceDelegate.h"

@interface PHLocationService : NSObject <CLLocationManagerDelegate>
@property (nonatomic, weak) id<PHLocationServiceDelegate> delegate;
- (void)startMonitoringSignificantLocationChanges;
- (void)startMonitoringPreciseLocationChanges;
- (void)stopMonitoringLocation;
- (void)updateGeofencesFromTags:(NSArray *)tagsOld toTags:(NSArray *)tagsNew;
- (void)triggerEnterTagRegionForFirstTagContainingCoordinate:(CLLocationCoordinate2D)coordinate;
@end
