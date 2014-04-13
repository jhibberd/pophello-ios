
#import "MWLogging.h"
#import <CoreLocation/CoreLocation.h>
#import "PHServiceAvailabilityMonitor.h"

@implementation PHServiceAvailabilityMonitor {
    
    id<PHServiceAvailabilityDelegate> _delegate;
    
    BOOL _isRegionMonitoringSupportedByDevice;
    BOOL _isMultitaskingSupportedByDevice;
    BOOL _isBackgroundAppRefreshAvailable;
    BOOL _isRegionMonitoringAvailable;
    BOOL _isLocationServicesAuthorized;
    BOOL _isLocationServicesEnabled;
    BOOL _isLocalStorageAvailable;
    
    PHServiceAvailabilityState _availability;
}

- (id)initWithDelegate:(id<PHServiceAvailabilityDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        
        // checked initially
        _isRegionMonitoringSupportedByDevice = NO;
        _isMultitaskingSupportedByDevice = NO;
        _isBackgroundAppRefreshAvailable = NO;
        _isLocationServicesAuthorized = NO;
        _isLocationServicesEnabled = NO;
        
        // assumed to be working unless a failure is reported
        _isRegionMonitoringAvailable = YES;
        _isLocalStorageAvailable = YES;
        
        _availability = PHServiceAvailabilityStateUnavailable;
        
        // subscribe to settings changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundRefreshStatusDidChange:)
                                                     name:UIApplicationBackgroundRefreshStatusDidChangeNotification
                                                   object:nil];
    }
    return self;
}

// Return the current availability state of the service.
//
- (PHServiceAvailabilityState)availability
{
    return _availability;
}

// If the service is unavailable return the most relevant human-friendly error message to be display in the main UI.
//
// A relevant error message will be a message that relates to a missing feature that a user has influence over, as
// opposed to an error for a missing feature not supported by the device.
//
- (NSString *)getMostRelevantHumanErrorMessage
{
    // setting the user can probably change
    if (!_isLocationServicesAuthorized) {
        return NSLocalizedString(@"SERVICE_UNAVAILABLE_IS_LOCATION_SERVICES_AUTHORIZED", nil);
    };
    if (!_isLocationServicesEnabled) {
        return NSLocalizedString(@"SERVICE_UNAVAILABLE_IS_LOCATION_SERVICES_ENABLED", nil);
    };
    if (!_isBackgroundAppRefreshAvailable) {
        return NSLocalizedString(@"SERVICE_UNAVAILABLE_IS_BACKGROUND_APP_REFRESH_AVAILABLE", nil);
    };

    // unexpected error
    if (!_isRegionMonitoringAvailable) {
        return NSLocalizedString(@"SERVICE_UNAVAILABLE_IS_REGION_MONITORING_AVAILABLE", nil);
    };
    if (!_isLocalStorageAvailable) {
        return NSLocalizedString(@"SERVICE_UNAVAILABLE_IS_LOCAL_STORAGE_AVAILABLE", nil);
    };
    
    // unsupported device
    if (!_isRegionMonitoringSupportedByDevice) {
        return NSLocalizedString(@"SERVICE_UNAVAILABLE_IS_REGION_MONITORING_SUPPORTED_BY_DEVICE", nil);
    };
    if (!_isMultitaskingSupportedByDevice) {
        return NSLocalizedString(@"SERVICE_UNAVAILABLE_IS_MULTITASKING_SUPPORT_BY_DEVICE", nil);
    };

    return nil; // service is available, shouldn't happen
}


#pragma mark - Initial Checks

// Perform initial service availability checks when the app is launched.
//
- (void)checkAvailability
{
    [self checkIsRegionMonitoringSupportedByDevice];
    [self checkIsMultitaskingSupportedByDevice];
    [self checkIsBackgroundAppRefreshAvailable];
    [self checkIsLocationServicesAuthorized];
    [self checkIsLocationServicesEnabled];
    [self updateAvailabilityAndNotifyDelegateIfChanged:NO];
}

// Region monitoring must be supported by the device for monitoring of tag geofences.
//
// The device either supports this feature or doesn't so it won't change.
//
- (void)checkIsRegionMonitoringSupportedByDevice
{
    _isRegionMonitoringSupportedByDevice = [CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]];
}

// Multitasking must be supported to allow the Zone Manager to update the zone using a background task while the app is
// running in the background:
// https://developer.apple.com/library/ios/documentation/iphone/conceptual/iphoneosprogrammingguide/ManagingYourApplicationsFlow/ManagingYourApplicationsFlow.html#//apple_ref/doc/uid/TP40007072-CH4-SW20
//
// The device either supports this feature or doesn't so it won't change.
//
- (void)checkIsMultitaskingSupportedByDevice
{
    _isMultitaskingSupportedByDevice = [UIDevice currentDevice].multitaskingSupported;
}

// Background App Refresh must be available in order for the app to be launched by the OS in response to a significant
// location update.
// https://developer.apple.com/library/ios/documentation/userexperience/conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html
//
// This is a setting that can be changed by the user unless the setting is restricted (eg. by parental controls).
// Monitoring of changes to this setting are handled by `backgroundRefreshStatusDidChange:`.
//
- (void)checkIsBackgroundAppRefreshAvailable
{
    _isBackgroundAppRefreshAvailable =
        [[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable;
}

// Location Services must be authorized for this app by the user.
//
// This is a setting that can be changed by the user unless the setting is restricted (eg. by parental controls).
// Changes to this user setting are monitored by the app.
//
- (void)checkIsLocationServicesAuthorized
{
    _isLocationServicesAuthorized = [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized;
}

// Location service must be enabled on the device.
//
// This is a setting that can be changed by the user. Monitoring of changes to this setting is also handled by
// `locationAuthorizationStatusDidChange:`.
//
- (void)checkIsLocationServicesEnabled
{
    _isLocationServicesEnabled = [CLLocationManager locationServicesEnabled];
}


#pragma mark - Failure & Settings Change Handling

- (void)updateAvailabilityAndNotifyDelegateIfChanged:(BOOL)notify
{
    BOOL isAvailableUpdated;
    if ([self isFirstAvailabilityCheck]) {
        isAvailableUpdated = PHServiceAvailabilityStatePending;
    } else {
        isAvailableUpdated =
            _isRegionMonitoringSupportedByDevice &&
            _isMultitaskingSupportedByDevice &&
            _isBackgroundAppRefreshAvailable &&
            _isRegionMonitoringAvailable &&
            _isLocationServicesAuthorized &&
            _isLocationServicesEnabled &&
            _isLocalStorageAvailable ? PHServiceAvailabilityStateAvailable : PHServiceAvailabilityStateUnavailable;
    }
    BOOL changed = isAvailableUpdated == _availability;
    _availability = isAvailableUpdated;
    if (changed && notify) {
        switch (_availability) {
            case PHServiceAvailabilityStateAvailable:
                MWLogInfo(@"Service did become available");
                [_delegate serviceDidBecomeAvailable];
                break;
            case PHServiceAvailabilityStateUnavailable:
                MWLogInfo(@"Service did become unavailable");
                [_delegate serviceDidBecomeUnavailable];
                break;
            case PHServiceAvailabilityStatePending:
                // shouldn't happen, `notify` will always be NO for the first check
                break;
        }
    }
}

// Return whether this is the first time that a service availability test has been performed.
//
// This caters for iOS prompting the user to enable location services only the first time it is requested.
//
- (BOOL)isFirstAvailabilityCheck
{
    static NSString *const key = @"firstServiceAvailabilityCheck";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:key]) {
        return NO;
    } else {
        [defaults setBool:YES forKey:key];
        [defaults synchronize];
        return YES;
    }
}

// Region monitoring must be supported by the device for monitoring of tag geofences.
//
// The CLLocationManager may report that it failed to monitor a geofence/region.
//
- (void)regionMonitoringDidFail:(NSError *)error
{
    MWLogError(@"Region monitoring failed: %@", [error localizedDescription]);
    _isRegionMonitoringAvailable = NO;
    [self updateAvailabilityAndNotifyDelegateIfChanged:YES];
}

// Local storage must be supported to persist tag data.
//
// Core Data may report that it failed to read/write data.
//
- (void)localStorageDidFail:(NSError *)error
{
    MWLogError(@"Local storage failed: %@", [error localizedDescription]);
    _isLocalStorageAvailable = NO;
    [self updateAvailabilityAndNotifyDelegateIfChanged:YES];
}

// Respond to an authorization status change for location services made by the user.
//
- (void)locationAuthorizationStatusDidChange:(CLAuthorizationStatus)status
{
    MWLogWarning(@"Location authorization status changed: %d", status);
    switch (status) {
        case kCLAuthorizationStatusAuthorized:
            _isLocationServicesAuthorized = YES;
            break;
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted:
            _isLocationServicesAuthorized = NO;
            break;
    }
    [self updateAvailabilityAndNotifyDelegateIfChanged:YES];
}

// Handle change to Background App Refresh setting.
//
- (void)backgroundRefreshStatusDidChange:(NSNotification *)notification
{
    _isBackgroundAppRefreshAvailable =
        [[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable;
    MWLogWarning(@"Background App Refresh setting changed: %d", _isBackgroundAppRefreshAvailable);
    [self updateAvailabilityAndNotifyDelegateIfChanged:YES];
}

@end