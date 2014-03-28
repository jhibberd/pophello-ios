
#import <CoreLocation/CoreLocation.h>
#import "PHZoneServiceAvailabilityMonitor.h"
#import "PHZoneServiceRequirement.h"

@implementation PHZoneServiceAvailabilityMonitor {
    BOOL _showingAsAvailable;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        // initially the service is assumed to be available
        _isHardwareSupported = YES;
        _isLocationServicesEnabled = YES;
        _isLocationServicesAuthorized = YES;
        _isBackgroundRefreshAvailable = YES;
        _isRegionMonitoringAvailable = YES;
        _isMultitaskingSupported = YES;
        
        _showingAsAvailable = YES;
    }
    return self;
}

// TODO not sure I like this
- (BOOL)performPreliminaryChecks
{
    BOOL available = YES;
    PHZoneServiceRequirement missingRequirement = -1;
    
    if (![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        _isHardwareSupported = NO;
        missingRequirement = kPHZoneServiceRequirementRegionMonitoringAvailable;
        available = NO;
    }
    
    if (![CLLocationManager locationServicesEnabled]) {
        _isLocationServicesEnabled = NO;
        missingRequirement = kPHZoneServiceRequirementLocationServicesEnabled;
        available = NO;
    }
    
    if (![UIDevice currentDevice].multitaskingSupported) {
        _isMultitaskingSupported = NO;
        missingRequirement = kPHZoneServiceRequirementMultitaskingSupported;
        available = NO;
    }
    
    [self updateServiceAvailabilityFollowingChangeTo:missingRequirement];
    return available;
}

- (void)setIsHardwareSupported:(BOOL)isHardwareSupported
{
    _isHardwareSupported = isHardwareSupported;
    [self updateServiceAvailabilityFollowingChangeTo:kPHZoneServiceRequirementHardwareSupport];
}

- (void)setIsLocationServicesEnabled:(BOOL)isLocationServicesEnabled
{
    _isLocationServicesEnabled = isLocationServicesEnabled;
    [self updateServiceAvailabilityFollowingChangeTo:kPHZoneServiceRequirementLocationServicesEnabled];
}

- (void)setIsLocationServicesAuthorized:(BOOL)isLocationServicesAuthorized
{
    _isLocationServicesAuthorized = isLocationServicesAuthorized;
    [self updateServiceAvailabilityFollowingChangeTo:kPHZoneServiceRequirementLocationServicesAuthorized];
}

// required for receiving location updates while running in the background
- (void)setIsBackgroundRefreshAvailable:(BOOL)isBackgroundRefreshAvailable
{
    _isBackgroundRefreshAvailable = isBackgroundRefreshAvailable;
    [self updateServiceAvailabilityFollowingChangeTo:kPHZoneServiceRequirementBackgroundRefreshAvailable];
}

- (void)setIsRegionMonitoringAvailable:(BOOL)isRegionMonitoringAvailable
{
    _isRegionMonitoringAvailable = isRegionMonitoringAvailable;
    [self updateServiceAvailabilityFollowingChangeTo:kPHZoneServiceRequirementRegionMonitoringAvailable];
}

// required for long running background task that locates the device and establishes a new zone
- (void)setIsMultitaskingSupported:(BOOL)isMultitaskingSupported
{
    _isMultitaskingSupported = isMultitaskingSupported;
    [self updateServiceAvailabilityFollowingChangeTo:kPHZoneServiceRequirementMultitaskingSupported];
}

- (void)updateServiceAvailabilityFollowingChangeTo:(PHZoneServiceRequirement)requirement
{
    BOOL shouldBeAvailable =
        _isHardwareSupported &&
        _isLocationServicesEnabled &&
        _isLocationServicesAuthorized &&
        _isBackgroundRefreshAvailable &&
        _isRegionMonitoringAvailable &&
        _isMultitaskingSupported;
    if (shouldBeAvailable && !_showingAsAvailable) {
        [self.delegate zoneServiceDidBecomeAvailable];
        _showingAsAvailable = YES;
    } else if (!shouldBeAvailable && _showingAsAvailable) {
        [self.delegate zoneServiceDidBecomeUnavailable:requirement];
        _showingAsAvailable = NO;
    }
}

@end
