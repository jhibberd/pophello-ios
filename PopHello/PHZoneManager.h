
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "PHLocationService.h"
#import "PHLocationServiceDelegate.h"
#import "PHStoreManager.h"
#import "PHZoneManagerDelegate.h"
#import "PopHello-Swift.h"

@interface PHZoneManager : NSObject <PHLocationServiceDelegate>
@property (nonatomic, weak) id<PHZoneManagerDelegate> delegate;
- (id)initWithStoreManager:(PHStoreManager *)storeManager
           locationService:(PHLocationService *)locationService
                    server:(Server *)server;
- (void)startMonitoringSignificantLocationChanges;
- (void)startMonitoringPreciseLocationChanges;
- (void)stopMonitoringLocationChanges;
- (void)offline;
- (CLLocationCoordinate2D)getLastPreciseLocation;
- (NSDictionary *)getActiveTag;
- (void)removeTag:(NSString *)tagID;
@end
