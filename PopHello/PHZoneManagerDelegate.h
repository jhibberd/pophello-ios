
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@protocol PHZoneManagerDelegate <NSObject>
- (void)didEnterTagRegion:(NSDictionary *)tag;
- (void)didExitTagRegion:(NSDictionary *)tag;
@end
