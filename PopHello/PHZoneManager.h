
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "PHLocationService.h"
#import "PHLocationServiceDelegate.h"
#import "PHServer.h"
#import "PHStoreManager.h"
#import "PHZoneManagerDelegate.h"

@interface PHZoneManager : NSObject <PHLocationServiceDelegate>
@property (nonatomic, weak) id<PHZoneManagerDelegate> delegate;
- (id)initWithStoreManager:(PHStoreManager *)storeManager
           locationService:(PHLocationService *)locationService
                    server:(PHServer *)server;
- (void)startMonitoringSignificantLocationChanges;
- (void)startMonitoringPreciseLocationChanges;
- (void)stopMonitoringLocationChanges;
- (void)offline;
- (CLLocationCoordinate2D)getLastPreciseLocation;
- (NSDictionary *)getActiveTag;
- (void)removeTag:(NSString *)tagID;
@end
