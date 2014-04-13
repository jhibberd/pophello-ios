
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "PHServiceAvailabilityDelegate.h"

typedef NS_ENUM(NSUInteger, PHServiceAvailabilityState) {
    PHServiceAvailabilityStatePending,
    PHServiceAvailabilityStateAvailable,
    PHServiceAvailabilityStateUnavailable
};

@interface PHServiceAvailabilityMonitor : NSObject
- (id)initWithDelegate:(id<PHServiceAvailabilityDelegate>)delegate;
- (PHServiceAvailabilityState)availability;
- (NSString *)getMostRelevantHumanErrorMessage;
- (void)checkAvailability;
- (void)regionMonitoringDidFail:(NSError *)error;
- (void)localStorageDidFail:(NSError *)error;
- (void)locationAuthorizationStatusDidChange:(CLAuthorizationStatus)status;
@end
