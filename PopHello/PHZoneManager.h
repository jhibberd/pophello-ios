
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "PHLocationService.h"
#import "PHLocationServiceDelegate.h"
#import "PHServer.h"
#import "PHTagActiveStore.h"
#import "PHTagsStore.h"
#import "PHZoneManagerDelegate.h"

@interface PHZoneManager : NSObject <PHLocationServiceDelegate>
@property (nonatomic, weak) id<PHZoneManagerDelegate> delegate;
- (id)initWithTagsStore:(PHTagsStore *)tagsStore
         tagActiveStore:(PHTagActiveStore *)tagActiveStore
        locationService:(PHLocationService *)locationService
                 server:(PHServer *)server;
- (void)startMonitoringSignificantLocationChanges;
- (void)startMonitoringPreciseLocationChanges;
- (void)stopMonitoringLocationChanges;
- (CLLocationCoordinate2D)getLastPreciseLocation;
- (NSDictionary *)getActiveTag;
@end
