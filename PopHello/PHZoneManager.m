
#import "MWLogging.h"
#import "PHLocationService.h"
#import "PHZoneManager.h"
#import "PHZoneServiceAvailabilityMonitor.h"

typedef NS_ENUM(NSUInteger, PHLocationUpdateMode) {
    kPHLocationUpdateModeNone,
    kPHLocationUpdateModeSignificant,
    kPHLocationUpdateModePrecise
};

// Manages the zone by coordinating between the location service, server, tags store and active tag store.
//
@implementation PHZoneManager {
    PHLocationService *_locationService;
    PHServer *_server;
    PHTagsStore *_tagsStore;
    PHTagActiveStore *_tagActiveStore;
    CLLocationCoordinate2D _lastPreciseLocation;
    PHZoneServiceAvailabilityMonitor *_serviceAvailabilityMonitor;
    UIBackgroundTaskIdentifier _backgroundTaskQueryServer;
    PHLocationUpdateMode _locationUpdateMode;
}

- (id)initWithTagsStore:(PHTagsStore *)tagsStore
         tagActiveStore:(PHTagActiveStore *)tagActiveStore
                 server:(PHServer *)server
{
    self = [super init];
    if (self) {
        
        _locationService = [[PHLocationService alloc] init];
        _locationService.delegate = self;
        _server = server;
        _tagsStore = tagsStore;
        _tagActiveStore = tagActiveStore;
        _serviceAvailabilityMonitor = [[PHZoneServiceAvailabilityMonitor alloc] init];
        _serviceAvailabilityMonitor.delegate = self;
        _lastPreciseLocation = kCLLocationCoordinate2DInvalid;
        _locationUpdateMode = kPHLocationUpdateModeNone;
    }
    return self;
}

- (void)startMonitoringSignificantLocationChanges
{
    switch (_locationUpdateMode) {
        case kPHLocationUpdateModePrecise:
            [self stopMonitoringPreciseLocationChanges];
            break;
        case kPHLocationUpdateModeSignificant:
            return;
        case kPHLocationUpdateModeNone:
            break;
    }
    [_locationService startMonitoringSignificantLocationChanges];
    _locationUpdateMode = kPHLocationUpdateModeSignificant;
}

- (void)startMonitoringPreciseLocationChanges
{
    switch (_locationUpdateMode) {
        case kPHLocationUpdateModePrecise:
            return;
        case kPHLocationUpdateModeSignificant:
            [self stopMonitoringSignificantLocationChanges];
            break;
        case kPHLocationUpdateModeNone:
            break;
    }
    [_locationService startMonitoringPreciseLocationChanges];
    _locationUpdateMode = kPHLocationUpdateModePrecise;
}

- (void)stopMonitoringLocationChanges
{
    switch (_locationUpdateMode) {
        case kPHLocationUpdateModePrecise:
            [self stopMonitoringPreciseLocationChanges];
            break;
        case kPHLocationUpdateModeSignificant:
            [self stopMonitoringSignificantLocationChanges];
            break;
        case kPHLocationUpdateModeNone:
            return;
    }
    [_locationService stopMonitoringLocation];
    _locationUpdateMode = kPHLocationUpdateModeNone;
}

- (void)stopMonitoringSignificantLocationChanges
{
    [self clearZone];
}

- (void)stopMonitoringPreciseLocationChanges
{
    _lastPreciseLocation = kCLLocationCoordinate2DInvalid;
}

- (BOOL)performPreliminaryServiceAvailabilityChecks
{
    return [_serviceAvailabilityMonitor performPreliminaryChecks];
}

// Clear the zone.
//
// Either because significant region monitoring has stopped and so we can't be sure of the accuracy of existing tags or
// because new tag data has been received and we need to clear the existing zone in preparation for creating a new one.
//
- (void)clearZone
{
    // TODO: don't we need to clear the tag notification too? perhaps another call to app delegate?
    // TODO: perhaps need to think what happens if transitioning to new zone and still in same tag, don't want it to
    // bounce
    [_locationService destroyTagGeofences];
    [_tagsStore clear];
    // TODO: might be a bug here; what if the user is still in the same tag region when moving to a new zone?
    // TODO: dismiss notifications too, but not here
    [_tagActiveStore clear];
}

- (CLLocationCoordinate2D)getLastPreciseLocation
{
    return _lastPreciseLocation;
}

- (NSDictionary *)getActiveTag
{
    return [_tagActiveStore fetch];
}


#pragma mark - PHLocationManagerDelegate

- (void)deviceDidUpdateSignificantLocation:(CLLocationCoordinate2D)center
{
    MWLogInfo(@"Establishing zone (lat=%f, lng=%f)", center.latitude, center.longitude);
    UIApplication* application = [UIApplication sharedApplication];
    
    // It's OK to call this when the app is in the foreground. It also means that if the app moves into the background
    // part way through a server call the task will be protected from early termination for being marked as a
    // background task.
    _backgroundTaskQueryServer = [application beginBackgroundTaskWithExpirationHandler:^{
        
        // this block must exit quickly to prevent the app being killed by the OS
        MWLogWarning(@"Failed to establish new zone within allocated background time; starting location updates");
        [_locationService destroyTagGeofences];
        [application endBackgroundTask:_backgroundTaskQueryServer];
        _backgroundTaskQueryServer = UIBackgroundTaskInvalid;
        
    }];
    if (_backgroundTaskQueryServer == UIBackgroundTaskInvalid) {
        MWLogCritical(@"Running tasks in the background is not possible");
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Make a local copy of the background task ID (inside the block) so that once the non-trivial workload (ie.
        // querying the server) is complete it is possible to check whether a more recent background thread has been
        // started. If so, just dismiss the current task. This can happen under edge scenarios, such as bouncing
        // whether Location Services are enabled while the application is running in the background.
        UIBackgroundTaskIdentifier taskId = _backgroundTaskQueryServer;
        
        // query server for tags (which takes a non-trivial amount of time)
        [_server queryForZoneTags:center successHandler:^(NSArray *tags) {
            
            // check the task is still valid (see comment above)
            if (taskId != _backgroundTaskQueryServer) {
                MWLogWarning(@"Dismissing background task because a more recent task has been started");
                // technically it's already been terminated so no use in calling `endBackgroundTask`
                return;
            }
            
            // TODO check that the service is still available
            
            // If the device has moved outside the region since establishing the zone then discard the zone and start
            // location the device again. This is because a zone established with the device already outside it will
            // never trigger an event for the device leaving the region and so zones will cease to be updated.
            // Background location updates are terminated along with this background task.
            [self clearZone];
            [_locationService buildTagGeofences:tags];
            [_tagsStore put:tags];
            MWLogInfo(@"Established zone (lat=%f, lng=%f, tags=%d)", center.latitude, center.longitude, [tags count]);
            [_locationService triggerEnterTagRegionForFirstTagContainingCoordinate:center];
            
            [application endBackgroundTask:_backgroundTaskQueryServer];
            _backgroundTaskQueryServer = UIBackgroundTaskInvalid;

        } errorHandler:^(NSDictionary *response) {
            MWLogError(@"Server error while building zone");
            [_locationService destroyTagGeofences];
            [application endBackgroundTask:_backgroundTaskQueryServer];
            _backgroundTaskQueryServer = UIBackgroundTaskInvalid;
            
        }];
        
    });
}

- (void)deviceDidUpdatePreciseLocation:(CLLocationCoordinate2D)center
{
    _lastPreciseLocation = center;
}

// Handle device entering tag geofence.
//
// Maintain the current active tag in local storage so that it persists in the event of the app being killed. When the
// app is launched it can check quickly in local storage to see which tag (if any) should be shown to the user.
//
- (void)didEnterTagRegion:(NSString *)tagId
{
    NSDictionary *tag = [_tagsStore fetch:tagId];
    if (tag == nil) {
        NSLog(@"Entered region for tag not found in local storage");
        return;
    }
    [_tagActiveStore put:tag];
    [self.delegate didEnterTagRegion:tag];
}

// Handle device exiting tag geofence.
//
// Clear the tag from being the active tag in local storage if it currently is. It may not be due to overlapping tag
// geofences.
//
- (void)didExitTagRegion:(NSString *)tagId
{
    NSDictionary *tag = [_tagsStore fetch:tagId];
    if (tag == nil) {
        NSLog(@"Exited region for tag not found in local storage");
        return;
    }
    [_tagActiveStore clearIfActive:tag];
    [self.delegate didExitTagRegion:tag];
}

- (void)monitoringDidFailForRegion
{
    _serviceAvailabilityMonitor.isRegionMonitoringAvailable = NO;
}

- (void)locationServicesDidChangeAuthorizationStatus:(BOOL)authorized
{
    _serviceAvailabilityMonitor.isLocationServicesAuthorized = authorized;
}


#pragma mark - PHZoneServiceAvailabilityMonitorDelegate

- (void)zoneServiceDidBecomeAvailable
{
    [self.delegate zoneServiceDidBecomeAvailable];
}

- (void)zoneServiceDidBecomeUnavailable:(PHZoneServiceRequirement)missing
{
    [self.delegate zoneServiceDidBecomeUnavailable:missing];
}

@end
