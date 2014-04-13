
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@protocol PHLocationServiceDelegate <NSObject>
- (void)deviceDidUpdateSignificantLocation:(CLLocationCoordinate2D)center;
- (void)deviceDidUpdatePreciseLocation:(CLLocationCoordinate2D)center;
- (void)didEnterTagRegion:(NSString *)tagId;
- (void)didExitTagRegion:(NSString *)tagId;
@end
