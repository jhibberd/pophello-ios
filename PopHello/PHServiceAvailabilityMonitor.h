
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "PHServiceAvailabilityDelegate.h"

@interface PHServiceAvailabilityMonitor : NSObject
- (id)initWithDelegate:(id<PHServiceAvailabilityDelegate>)delegate;
- (BOOL)isAvailable;
- (NSString *)getMostRelevantHumanErrorMessage;
- (void)checkAvailability;
- (void)regionMonitoringDidFail:(NSError *)error;
- (void)localStorageDidFail:(NSError *)error;
- (void)locationAuthorizationStatusDidChange:(CLAuthorizationStatus)status;
@end
