
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "PHLocationServiceDelegate.h"
#import "PHServer.h"
#import "PHTagActiveStore.h"
#import "PHTagsStore.h"
#import "PHZoneManagerDelegate.h"
#import "PHZoneServiceAvailabilityMonitorDelegate.h"

@interface PHZoneManager : NSObject <PHLocationServiceDelegate, PHZoneServiceAvailabilityMonitorDelegate>
@property (nonatomic, weak) id<PHZoneManagerDelegate> delegate;
- (id)initWithTagsStore:(PHTagsStore *)tagsStore
         tagActiveStore:(PHTagActiveStore *)tagActiveStore
                 server:(PHServer *)server;
- (void)startMonitoringSignificantLocationChanges;
- (void)startMonitoringPreciseLocationChanges;
- (void)stopMonitoringLocationChanges;
- (CLLocationCoordinate2D)getLastPreciseLocation;
- (NSDictionary *)getActiveTag;
- (BOOL)performPreliminaryServiceAvailabilityChecks;
@end
