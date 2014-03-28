
#import "MWLogging.h"
#import "PHLocationService.h"

static CLLocationDistance const kPHRegionTagRadius = 100; // meters

typedef NS_ENUM(NSUInteger, PHLocationUpdateMode) {
    kPHLocationUpdateModeNone,
    kPHLocationUpdateModeSignificant,
    kPHLocationUpdateModePrecise
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
    PHLocationUpdateMode _locationUpdateMode;
}

- (id)init
{
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationUpdateMode = kPHLocationUpdateModeNone;
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
        case kPHLocationUpdateModeNone:
            break;
        case kPHLocationUpdateModePrecise:
            [self stopMonitoringPreciseLocationChanges];
            break;
        case kPHLocationUpdateModeSignificant:
            return;
    }
    [_locationManager startMonitoringSignificantLocationChanges];
    _locationUpdateMode = kPHLocationUpdateModeSignificant;
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
        case kPHLocationUpdateModeNone:
            break;
        case kPHLocationUpdateModePrecise:
            return;
        case kPHLocationUpdateModeSignificant:
            [self stopMonitoringSignificantLocationChanges];
            break;
    }
    [_locationManager startUpdatingLocation];
    _locationUpdateMode = kPHLocationUpdateModePrecise;
}

- (void)stopMonitoringLocation
{
    MWLogInfo(@"Stopped monitoring location changes");
    switch (_locationUpdateMode) {
        case kPHLocationUpdateModeNone:
            return;
        case kPHLocationUpdateModePrecise:
            [self stopMonitoringPreciseLocationChanges];
            break;
        case kPHLocationUpdateModeSignificant:
            [self stopMonitoringSignificantLocationChanges];
            break;
    }
    _locationUpdateMode = kPHLocationUpdateModeNone;
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
        case kPHLocationUpdateModeSignificant:
            [self.delegate deviceDidUpdateSignificantLocation:location.coordinate];
            break;
            
        case kPHLocationUpdateModePrecise:
            [self.delegate deviceDidUpdatePreciseLocation:location.coordinate];
            break;
            
        case kPHLocationUpdateModeNone:
            break; // ignore, not interested in location updates
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
    MWLogWarning(@"Location services authorization status changed: %d", status);
    switch (status) {
        case kCLAuthorizationStatusAuthorized:
            [self.delegate locationServicesDidChangeAuthorizationStatus:YES];
            break;
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted:
            [self.delegate locationServicesDidChangeAuthorizationStatus:NO];
            break;
    }
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
    MWLogError(@"Region monitoring failed: %@", [error localizedDescription]);
    [self.delegate monitoringDidFailForRegion];
}

// Monitor a geofence for each tag in the zone.
//
- (void)buildTagGeofences:(NSArray *)tags
{
    MWLogInfo(@"Creating geofences");
    for (NSDictionary *tag in tags) {
        CLLocationDegrees lat = [tag[@"lat"] doubleValue];
        CLLocationDegrees lng = [tag[@"lng"] doubleValue];
        NSString *tagId = tag[@"id"];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(lat, lng);
        CLRegion *region = [[CLCircularRegion alloc] initWithCenter:center
                                                             radius:kPHRegionTagRadius
                                                         identifier:tagId];
        [_locationManager startMonitoringForRegion:region];
    }
}

// although the documentation states that by monitoring a region with the same identifier as an existing region, the
// new region will replace the existing region, in practice this wasn't happending and monitoring for the existing
// region had to be explicitly stopped
//
- (void)destroyTagGeofences
{
    MWLogInfo(@"Destroying geofences");
    for (CLRegion *region in _locationManager.monitoredRegions) {
        [_locationManager stopMonitoringForRegion:region];
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
