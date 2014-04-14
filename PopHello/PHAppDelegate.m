
#import <BugSense-iOS/BugSenseController.h>
#import "MWLogging.h"
#import "PHAppDelegate.h"
#import "PHLocationService.h"
#import "PHLogRecorder.h"
#import "PHMainViewController.h"
#import "PHServer.h"
#import "PHServiceAvailabilityMonitor.h"
#import "PHStoreManager.h"
#import "PHTagNotification.h"
#import "PHZoneManager.h"

@implementation PHAppDelegate {
    PHLocationService *_locationService;
    PHZoneManager *_zoneManager;
    PHServer *_server;
    PHStoreManager *_storeManager;
    PHMainViewController *_mainView;
    PHServiceAvailabilityMonitor *_serviceAvailabilityMonitor;
}

#pragma mark - Application

// Handle a request to launch the app.
//
// The app can be launched in the foreground by the user or in the background by the OS.
//
// The app can be launched by the user:
// - if they directly launch the app
// - if they click a tag local notification
//
// The app can be launched by the OS:
// - in response to a significant location update
// - in response to a geofence enter/exit transition
//
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // send usage stats and error reports to a third party server to analysis
    [BugSenseController sharedControllerWithBugSenseAPIKey:@"5b8a5499" userDictionary:nil sendImmediately:YES];
    
    //[PHLogRecorder record];
    MWLogInfo(@"Application launched");
    
    // manually set the root view controller to the main view controller so that the "unavailable" view controller
    // can be overlayed if necessary
    _mainView = [[PHMainViewController alloc] init];
    self.window.rootViewController = _mainView;
    [self.window makeKeyAndVisible];
    
    _serviceAvailabilityMonitor = [[PHServiceAvailabilityMonitor alloc] initWithDelegate:self];
    _storeManager = [[PHStoreManager alloc] initWithServiceAvailabilityMonitor:_serviceAvailabilityMonitor];
    _server = [[PHServer alloc] init];
    _locationService = [[PHLocationService alloc] initWithServiceAvailabilityMonitor:_serviceAvailabilityMonitor];
    _zoneManager = [[PHZoneManager alloc] initWithStoreManager:_storeManager
                                               locationService:_locationService
                                                        server:_server];
    _locationService.delegate = _zoneManager;
    _zoneManager.delegate = self;

    return YES;
}

// Handle application becoming active.
//
// The can only ever be one local notification and it will always be consistent with the active tag in local storage.
// When the app is launched or becomes active checking the active tag in local storage is sufficient to handle both the
// app being launched directly by the user or by the user clicking a local notification.
//
// Local notifications exist to notify the user of a significant event occurring in the app. If the app has just been
// launched by the user all local notifications can be cleared because they've served their purpose.
//
// It's necessary to dismiss all local notifications whenever significant location monitoring is stopped because it's
// not possible to ensure they are still relevant. This happens automatically in the logic below but needs to be a
// consideration if refactored.
//
// When the app is in the background it isn't always notified of changes that affect the availability of the service
// so always check when the app becomes active.
//
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    MWLogInfo(@"Application did become active");
    [PHTagNotification dismissAll];
    [_serviceAvailabilityMonitor checkAvailability];
    if ([_serviceAvailabilityMonitor isAvailable]) {
        [self initUI];
    } else {
        [_mainView presentServiceUnavailable:[_serviceAvailabilityMonitor getMostRelevantHumanErrorMessage]];
    }
}

// Initialise the user interface based on the current state of the zone.
//
- (void)initUI
{
    NSDictionary *tagActive = [_zoneManager getActiveTag];
    if (tagActive == nil) {
        MWLogInfo(@"showing create view");
        [_mainView presentTagCreate:_zoneManager server:_server delegate:self];
        [_zoneManager startMonitoringPreciseLocationChanges];
    } else {
        MWLogInfo(@"showing tag view");
        [_zoneManager stopMonitoringLocationChanges];
        [_mainView presentTagView:tagActive];
    }
}

// Handle app resigning active state.
//
// The app must be listening for significant location updates as it transitions to a background state because this uses
// less power and also means that if the app is killed by the OS it will be relaunched in response to significant
// location update.
//
// When the app is woken the UI should be empty and built from scratch. In preparation for this remove any view from
// the main controller. This isn't animated because at this point it's invisible to the user and this method must
// complete fast to avoid the app from being killed by the OS.
//
// If the service isn't available when resigning active state there is no point attempting to monitor for significant
// location updates or update the UI.
//
- (void)applicationWillResignActive:(UIApplication *)application
{
    MWLogInfo(@"Application will resign active");
    if (![_serviceAvailabilityMonitor isAvailable]) {
        return;
    }
    [_zoneManager startMonitoringSignificantLocationChanges];
    //[_mainView presentNothing];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    MWLogCritical(@"Application will terminate");
    [_storeManager saveContext];
}


#pragma mark - UI Event Handlers

// Handle the user submitting a request to the server to create a new tag.
//
// If the app is in the background when this message is received ignore it because we don't want to stop monitoring for
// significant location updates and there is no point in updating the UI. Although this is unlikely in this handler
// because the latency between the user submitting a request and this delegate receiving the message doesn't leave much
// of an opportunity for the app to be made inactive.
//
- (void)newTagCreationWasSubmitted
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    [_mainView presentPending];
}

// Handle the user successfully creating a tag.
//
// If the app is in the background when this message is received ignore it because we don't want to stop monitoring for
// significant location updates and there is no point in updating the UI.
//
- (void)newTagCreationDidSucceed
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    [_zoneManager stopMonitoringLocationChanges];
    [_mainView presentTagCreationSuccess];
}

// Handle an error occurring when the user tried to create a tag.
//
// If the app is in the background when this message is received ignore it because we don't want to stop monitoring for
// significant location updates and there is no point in updating the UI.
//
- (void)newTagCreationDidFail
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    [_zoneManager stopMonitoringLocationChanges];
    [_mainView presentTagCreationFailure];
}


#pragma mark - Region Events

// Handle the device entering a tag geofence.
//
// If the app is in the background dispatch a notification, otherwise take no action. The Zone Manager will have
// already updated the necessary resources in response to this event.
//
- (void)didEnterTagRegion:(NSDictionary *)tag
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        return;
    }
    MWLogInfo(@"Dispatching a local notification (tag=%@)", tag[@"id"]);
    dispatch_async(dispatch_get_main_queue(), ^{
        [PHTagNotification present:tag];
    });
}

// Handle the device exiting a tag geofence.
//
// In theory this event can be ignored if the app is running in the foreground because notifications are cleared when
// the app is launched by the user. For simplicity, and to be safe, notifications are dismissed regardless of app
// state.
//
- (void)didExitTagRegion:(NSDictionary *)tag
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [PHTagNotification dismissIfPresenting:tag];
    });
}


#pragma mark - Service Availability Events

// Respond to the service becoming available.
//
// If the app is active then load the user interface from the zone (which at this point should be empty). If the app
// is in the background then resume monitoring for significant location updates.
//
- (void)serviceDidBecomeAvailable
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self initUI];
    } else {
        [_zoneManager startMonitoringSignificantLocationChanges];
    }
}

- (void)serviceDidBecomeUnavailable
{
    [_zoneManager offline];
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [_mainView presentServiceUnavailable:[_serviceAvailabilityMonitor getMostRelevantHumanErrorMessage]];
    }
}

@end
