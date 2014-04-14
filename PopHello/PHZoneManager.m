
#import "MWLogging.h"
#import "NSArray+PHArray.h"
#import "PHTagActiveStore.h"
#import "PHTagsStore.h"
#import "PHTagNotification.h"
#import "PHZoneManager.h"

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
    UIBackgroundTaskIdentifier _backgroundTaskQueryServer;
    PHLocationUpdateMode _locationUpdateMode;
    BOOL _isOffline;
}

- (id)initWithStoreManager:(PHStoreManager *)storeManager
           locationService:(PHLocationService *)locationService
                    server:(PHServer *)server
{
    self = [super init];
    if (self) {
        _locationService = locationService;
        _server = server;
        _tagsStore = [[PHTagsStore alloc] initWithStoreManager:storeManager];
        _tagActiveStore = [[PHTagActiveStore alloc] initWithStoreManager:storeManager];
        _lastPreciseLocation = kCLLocationCoordinate2DInvalid;
        _locationUpdateMode = kPHLocationUpdateModeNone;
        _isOffline = YES;
    }
    return self;
}

- (void)startMonitoringSignificantLocationChanges
{
    _isOffline = NO;
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
    _isOffline = NO;
    switch (_locationUpdateMode) {
        case kPHLocationUpdateModePrecise:
            return;
        case kPHLocationUpdateModeSignificant:
            break;
        case kPHLocationUpdateModeNone:
            break;
    }
    [_locationService startMonitoringPreciseLocationChanges];
    _locationUpdateMode = kPHLocationUpdateModePrecise;
}

- (void)stopMonitoringLocationChanges
{
    _isOffline = NO;
    switch (_locationUpdateMode) {
        case kPHLocationUpdateModePrecise:
            [self stopMonitoringPreciseLocationChanges];
            break;
        case kPHLocationUpdateModeSignificant:
            break;
        case kPHLocationUpdateModeNone:
            return;
    }
    [_locationService stopMonitoringLocation];
    _locationUpdateMode = kPHLocationUpdateModeNone;
}

- (void)stopMonitoringPreciseLocationChanges
{
    _lastPreciseLocation = kCLLocationCoordinate2DInvalid;
}

- (CLLocationCoordinate2D)getLastPreciseLocation
{
    return _lastPreciseLocation;
}

- (NSDictionary *)getActiveTag
{
    return [_tagActiveStore fetch];
}

// Stop all activity and clear all state.
//
// This happens in response to the service becoming unavailable. After calling this method the only part of the Zone
// Manager that may still be active is a pending server request. The request callback first checks whether the Zone
// Manager is still online before processing the server response.
//
- (void)offline
{
    _isOffline = YES;
    [self stopMonitoringLocationChanges];
    [_locationService removeAllGeofences];
    [_tagActiveStore clear];
    [_tagsStore clear];
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
        MWLogWarning(@"Failed to establish new zone within allocated background time");
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
        [_server queryForZoneTags:center successHandler:^(NSArray *tagsNew) {
            
            // check the task is still valid (see comment above)
            if (taskId != _backgroundTaskQueryServer) {
                MWLogWarning(@"Dismissing background task because a more recent task has been started");
                // technically it's already been terminated so no use in calling `endBackgroundTask`
                return;
            }
            if (_isOffline) {
                MWLogInfo(@"Ignore server response; Zone Manager is offline");
            } else {
                [self updateZoneWithTags:tagsNew location:center];
            }
            [application endBackgroundTask:_backgroundTaskQueryServer];
            _backgroundTaskQueryServer = UIBackgroundTaskInvalid;

        } errorHandler:^(NSDictionary *response) {
            MWLogError(@"Server error while building zone");
            [application endBackgroundTask:_backgroundTaskQueryServer];
            _backgroundTaskQueryServer = UIBackgroundTaskInvalid;
        }];
        
    });
}

- (void)updateZoneWithTags:(NSArray *)tagsNew location:(CLLocationCoordinate2D)center
{
    NSArray *tagsOld = [_tagsStore fetchAll];
    [_tagsStore clear];
    [_tagsStore put:tagsNew];
    NSDictionary *tagActive = [_tagActiveStore fetch];
    BOOL keepTagActive = tagActive != nil && [tagsNew containsTagId:tagActive[@"id"]];
    if (!keepTagActive && tagActive != nil) {
        [_tagActiveStore clear];
        dispatch_async(dispatch_get_main_queue(), ^{
            [PHTagNotification dismissAll];
        });
    }
    [_locationService updateGeofencesFromTags:tagsOld toTags:tagsNew];
    if (!keepTagActive) {
        [_locationService triggerEnterTagRegionForFirstTagContainingCoordinate:center];
    }
    
    MWLogInfo(@"Zone old tags: %@", tagsOld);
    MWLogInfo(@"Zone new tags: %@", tagsNew);
    MWLogInfo(@"Zone established at %f, %f", center.latitude, center.longitude);
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

@end
