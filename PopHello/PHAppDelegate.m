
#import <BugSense-iOS/BugSenseController.h>
#import "MWLogging.h"
#import "PHAppDelegate.h"
#import "PHLogRecorder.h"
#import "PHMainViewController.h"
#import "PHServer.h"
#import "PHStoreManager.h"
#import "PHTagNotification.h"
#import "PHTagsStore.h"
#import "PHUnavailableViewController.h"
#import "PHZoneManager.h"

@implementation PHAppDelegate {
    PHZoneManager *_zoneManager;
    PHServer *_server;
    PHStoreManager *_storeManager;
    PHMainViewController *_mainView;
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
    
    [PHLogRecorder record];
    MWLogInfo(@"Application launched");
    
    // manually set the root view controller to the main view controller so that the "unavailable" view controller
    // can be overlayed if necessary
    _mainView = [[PHMainViewController alloc] init];
    self.window.rootViewController = _mainView;
    [self.window makeKeyAndVisible];
    
    _server = [[PHServer alloc] init];
    _storeManager = [[PHStoreManager alloc] init];
    PHTagsStore *tagsStore = [[PHTagsStore alloc] initWithStoreManager:_storeManager];
    PHTagActiveStore *tagActiveStore = [[PHTagActiveStore alloc] initWithStoreManager:_storeManager];
    _zoneManager = [[PHZoneManager alloc] initWithTagsStore:tagsStore tagActiveStore:tagActiveStore server:_server];
    _zoneManager.delegate = self;
    [_zoneManager performPreliminaryServiceAvailabilityChecks];
    
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
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    MWLogInfo(@"Application did become active");
    
    [PHTagNotification dismissAll];
    
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
- (void)applicationWillResignActive:(UIApplication *)application
{
    MWLogInfo(@"Application will resign active");
    [_zoneManager startMonitoringSignificantLocationChanges];
    [_mainView presentNothing];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    MWLogCritical(@"Application will terminate");
    [_storeManager saveContext];
}


#pragma mark - UI Event Handlers

// Handle the user successfully creating a tag.
//
// If the app is in the background when this message is received ignore it because we don't want to stop monitoring for
// significant location updates and there is no point in updating the UI.
//
- (void)tagCreateDidSucceed
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    [_zoneManager stopMonitoringLocationChanges];
    [_mainView presentTagCreateSuccess];
}

// Handle an error occurring when the user tried to create a tag.
//
// If the app is in the background when this message is received ignore it because we don't want to stop monitoring for
// significant location updates and there is no point in updating the UI.
//
- (void)tagCreateDidFail
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    [_zoneManager stopMonitoringLocationChanges];
    [_mainView presentTagCreateFailure];
}


#pragma mark - Region Events

// Notify the user that a tag region has been entered.
//
// This is only ever called when the app is running in the background.
//
- (void)didEnterTagRegion:(NSDictionary *)tag
{
    MWLogInfo(@"Dispatching a local notification (tag=%@)", tag[@"id"]);
    dispatch_async(dispatch_get_main_queue(), ^{
        [PHTagNotification present:tag];
    });
}

// Notify the user that a tag region has been exited.
//
// This is only ever called when the app is running in the background.
//
- (void)didExitTagRegion:(NSDictionary *)tag
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [PHTagNotification dismissIfPresenting:tag];
    });
}


#pragma mark - Zone Service Availability Events

- (void)zoneServiceDidBecomeAvailable
{
    MWLogInfo(@"Service did become available");
    [self.window.rootViewController dismissViewControllerAnimated:NO completion:nil]; // dismiss unavailable
    //[_zoneManager startBuildingZone];
}

- (void)zoneServiceDidBecomeUnavailable:(PHZoneServiceRequirement)missing
{
    // TODO this isn't working and there's a bug where if Location Services is disabled while the server is being
    // contacted this method gets called while the app is in the background but if Location Services is then enabled
    // (while the app is still in the background) then when the app is started there are two background tasks both
    // querying the server.
    
    // the zone service has become availably so reset the UI back to an initial state
    MWLogWarning(@"Service did become unavailable");
    [_mainView presentNothing]; // TODO: perhaps show "service unavailable" view
    
    // notify the user by presenting an appropriate view
    UIViewController *view = [[PHUnavailableViewController alloc] initWithMissingZoneServiceRequirement:missing];
    [self.window.rootViewController presentViewController:view animated:NO completion:nil];
}

@end
