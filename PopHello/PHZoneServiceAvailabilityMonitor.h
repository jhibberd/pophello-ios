
#import <Foundation/Foundation.h>
#import "PHZoneServiceAvailabilityMonitorDelegate.h"

@interface PHZoneServiceAvailabilityMonitor : NSObject
@property (nonatomic, weak) id<PHZoneServiceAvailabilityMonitorDelegate> delegate;
@property (nonatomic) BOOL isHardwareSupported;
@property (nonatomic) BOOL isLocationServicesEnabled;
@property (nonatomic) BOOL isLocationServicesAuthorized;
@property (nonatomic) BOOL isBackgroundRefreshAvailable;
@property (nonatomic) BOOL isRegionMonitoringAvailable;
@property (nonatomic) BOOL isMultitaskingSupported;
- (BOOL)performPreliminaryChecks;
@end
