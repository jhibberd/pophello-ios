
#import "MWLogging.h"
#import "NSArray+PHArray.h"
#import "PHLocationService.h"

static CLLocationDistance const kPHRegionTagRadius = 100; // meters

typedef NS_ENUM(NSUInteger, PHLocationUpdateMode) {
    PHLocationUpdateModeNone,
    PHLocationUpdateModePrompt,
    PHLocationUpdateModeSignificant,
    PHLocationUpdateModePrecise
};

// Provides the following location services:
//
// - Monitor for significant device location updates
// - Monitor for precise device location updates
// - Monitor for enter/exit tag geofence transitions
// - Create/destroy tag geofences
//
@implementation PHLocationService {
    CLLocationManager *_locationManager;
    PHServiceAvailabilityMonitor *_serviceAvailabilityMonitor;
    PHLocationUpdateMode _locationUpdateMode;
}

- (id)initWithServiceAvailabilityMonitor:(PHServiceAvailabilityMonitor *)serviceAvailabilityMonitor
{
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _serviceAvailabilityMonitor = serviceAvailabilityMonitor;
        _locationUpdateMode = PHLocationUpdateModeNone;
    }
    return self;
}


#pragma mark - Location Updating

// Start monitoring significant location updates using low power.
//
// Used to refresh the current zone while the app is in the background. Location updates will not be received unless
// the device moves roughly 500 meters, and no more than one every 5 minutes.
//
- (void)startMonitoringSignificantLocationChanges
{
    MWLogInfo(@"Started monitoring significant location changes");
    switch (_locationUpdateMode) {
        case PHLocationUpdateModeNone:
            break;
        case PHLocationUpdateModePrompt:
            [self stopMonitoringLocationForUserPrompt];
            break;
        case PHLocationUpdateModePrecise:
            [self stopMonitoringPreciseLocationChanges];
            break;
        case PHLocationUpdateModeSignificant:
            return;
    }
    [_locationManager startMonitoringSignificantLocationChanges];
    _locationUpdateMode = PHLocationUpdateModeSignificant;
}

// Start monitoring precise location updates using high power.
//
// Used to get the device's precise location while a tag is being composed. The default values for `distanceFilter` and
// `desiredAccuracy` already provide the greatest precision.
//
- (void)startMonitoringPreciseLocationChanges
{
    MWLogInfo(@"Started monitoring precise location changes");
    switch (_locationUpdateMode) {
        case PHLocationUpdateModeNone:
            break;
        case PHLocationUpdateModePrompt:
            [self stopMonitoringLocationForUserPrompt];
            break;
        case PHLocationUpdateModePrecise:
            return;
        case PHLocationUpdateModeSignificant:
            [self stopMonitoringSignificantLocationChanges];
            break;
    }
    [_locationManager startUpdatingLocation];
    _locationUpdateMode = PHLocationUpdateModePrecise;
}

// Begin requesting location updates so that the OS prompts the user to enable location services.
//
// As soon as a location update is received stop monitoring location updates. This method of monitoring location
// updates will always be called first so there is no need to stop any existing monitoring.
//
- (void)promptUserForAuthorization
{
    [_locationManager startUpdatingLocation];
    _locationUpdateMode = PHLocationUpdateModePrompt;
}

- (void)stopMonitoringLocation
{
    MWLogInfo(@"Stopped monitoring location changes");
    switch (_locationUpdateMode) {
        case PHLocationUpdateModeNone:
            return;
        case PHLocationUpdateModePrompt:
            [self stopMonitoringLocationForUserPrompt];
            break;
        case PHLocationUpdateModePrecise:
            [self stopMonitoringPreciseLocationChanges];
            break;
        case PHLocationUpdateModeSignificant:
            [self stopMonitoringSignificantLocationChanges];
            break;
    }
    _locationUpdateMode = PHLocationUpdateModeNone;
}

- (void)stopMonitoringLocationForUserPrompt
{
    [_locationManager stopUpdatingLocation];
}

- (void)stopMonitoringSignificantLocationChanges
{
    [_locationManager stopMonitoringSignificantLocationChanges];
}

- (void)stopMonitoringPreciseLocationChanges
{
    [_locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation* location = [locations lastObject];
    NSTimeInterval age = -[location.timestamp timeIntervalSinceNow];
    MWLogInfo(@"Location update (lat=%f, lng=%f, accuracy=%f, age=%f)",
              location.coordinate.latitude,
              location.coordinate.longitude,
              location.horizontalAccuracy,
              age);
    
    switch (_locationUpdateMode) {
        case PHLocationUpdateModeNone:
            break; // ignore, not interested in location updates
        case PHLocationUpdateModePrompt:
            // we don't need the location, we just need to prompt the user
            [self stopMonitoringLocation];
            break;
        case PHLocationUpdateModeSignificant:
            [self.delegate deviceDidUpdateSignificantLocation:location.coordinate];
            break;
        case PHLocationUpdateModePrecise:
            [self.delegate deviceDidUpdatePreciseLocation:location.coordinate];
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    MWLogError(@"Location update failed: %@", [error localizedDescription]);
    // TODO should probably stop updating location if we currently are but only under certain error conditions; other
    // error conditions appear to be temporary and correct themselves
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    MWLogWarning(@"Location updating was paused");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    MWLogWarning(@"Location updating was resumed");
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [_serviceAvailabilityMonitor locationAuthorizationStatusDidChange:status];
}


#pragma mark - Region Monitoring

// Notify the delegate that the device has entered a tag region.
//
// The region identifier is the tag ID.
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    MWLogInfo(@"Region entered (identifier=%@)", region.identifier);
    [self.delegate didEnterTagRegion:region.identifier];
}

// Notify the delegate that the device has exited a tag region.
//
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    MWLogInfo(@"Region exited (identifier=%@)", region.identifier); // region identifier is tag ID
    [self.delegate didExitTagRegion:region.identifier];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region
              withError:(NSError *)error
{
    [_serviceAvailabilityMonitor regionMonitoringDidFail:error];
}

// Update the tag geofences being monitored.
//
// Geofences are preserved if they also appear in the new set of tags.
//
- (void)updateGeofencesFromTags:(NSArray *)tagsOld toTags:(NSArray *)tagsNew
{
    MWLogInfo(@"Updating geofences");
    
    NSArray *tagsExpired = [tagsOld subarrayOfTagsNotIn:tagsNew];
    for (CLRegion *region in _locationManager.monitoredRegions) {
        NSString *tagId = region.identifier;
        
        if ([tagsExpired containsTagId:tagId]) {
            MWLogInfo(@"Deleting geofence: %@", region.identifier);
            [_locationManager stopMonitoringForRegion:region];
            continue;
        }
        
        // this shouldn't happen but from experience it does, so worth logging
        if (![tagsOld containsTagId:tagId]) {
            MWLogWarning(@"Deleting unknown geofence: %@", region.identifier);
            [_locationManager stopMonitoringForRegion:region];
            continue;
        }
    }
    
    NSArray *tagsRevealed = [tagsNew subarrayOfTagsNotIn:tagsOld];
    for (NSDictionary *tag in tagsRevealed) {
        CLLocationDegrees lat = [tag[@"lat"] doubleValue];
        CLLocationDegrees lng = [tag[@"lng"] doubleValue];
        NSString *tagId = tag[@"id"];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(lat, lng);
        CLRegion *region = [[CLCircularRegion alloc] initWithCenter:center
                                                             radius:kPHRegionTagRadius
                                                         identifier:tagId];
        [_locationManager startMonitoringForRegion:region];
        MWLogInfo(@"Created geofence: %@", region.identifier);
    }
}

// Check whether any tags contain the current device and dispatch a geofence enter event if they do.
//
// Core Location doesn't trigger a region boundary crossing if the device is currently inside the geofence when it's
// created. CLLocationManager exposes the method `requestStateForRegion:` which tests whether the device is currently
// in a given geofence, but only works on geofences that are sublasses of Map Kit classes. Android does this
// automatically.
//
// Only the first tag geofence to contain the coordinate triggers the event.
//
- (void)triggerEnterTagRegionForFirstTagContainingCoordinate:(CLLocationCoordinate2D)coordinate
{
    for (CLCircularRegion *region in _locationManager.monitoredRegions) {
        if ([region containsCoordinate:coordinate]) {
            [_delegate didEnterTagRegion:region.identifier]; // region indentifier is tag ID
            return;
        }
    }
}

@end
