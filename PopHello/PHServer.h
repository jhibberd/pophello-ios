
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface PHServer : NSObject
- (void)queryForZoneTags:(CLLocationCoordinate2D)center
          successHandler:(void (^)(NSArray *tags))successHandler
            errorHandler:(void (^)(NSDictionary *response))errorHandler;
- (void)postTagAt:(CLLocationCoordinate2D)center
             text:(NSString *)text
   successHandler:(void (^)())successHandler
     errorHandler:(void (^)(NSDictionary *response))errorHandler;
@end
