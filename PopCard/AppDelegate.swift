import UIKit
import CoreData

@UIApplicationMain
class AppDelegate:
        UIResponder,
        UIApplicationDelegate,
        TagCreateViewDelegate,
        TagViewDelegate,
        ZoneManagerDelegate,
        ServiceAvailabilityMonitorDelegate {
    
    var window: UIWindow?

    let BUNDLE_PROPERTY_USER_ID = "UserID"
    var locationService: LocationService!
    var zoneManager: ZoneManager!
    var server: Server!
    var storeManager: StoreManager!
    var mainView: MainViewController!
    var serviceAvailabilityMonitor: ServiceAvailabilityMonitor!
    

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
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {

        println("Application launched")
        
        // manually set the root view controller to the main view controller so that the "unavailable" view controller
        // can be overlayed if necessary
        mainView = MainViewController()
        window!.rootViewController = mainView
        window!.makeKeyAndVisible()
        
        // read values from the bundle required for initialising the core objects
        let bundle = NSBundle.mainBundle()
        let userID = bundle.objectForInfoDictionaryKey(BUNDLE_PROPERTY_USER_ID) as String
        
        serviceAvailabilityMonitor = ServiceAvailabilityMonitor(delegate: self)
        storeManager = StoreManager(serviceAvailabilityMonitor: serviceAvailabilityMonitor)
        server = Server(userID: userID)
        locationService = LocationService(serviceAvailabilityMonitor: serviceAvailabilityMonitor)
        zoneManager = ZoneManager(
            storeManager: storeManager, locationService: locationService, server: server, delegate: self)
        locationService.delegate = zoneManager
        
        application.registerForRemoteNotificationTypes(.Alert | .Sound)
        return true
    }

    // Handle application becoming active.
    //
    // The can only ever be one local notification and it will always be consistent with the active tag in local 
    // storage. When the app is launched or becomes active checking the active tag in local storage is sufficient to 
    // handle both the app being launched directly by the user or by the user clicking a local notification.
    //
    // Local notifications exist to notify the user of a significant event occurring in the app. If the app has just 
    // been launched by the user all local notifications can be cleared because they've served their purpose.
    //
    // It's necessary to dismiss all local notifications whenever significant location monitoring is stopped because 
    // it's not possible to ensure they are still relevant. This happens automatically in the logic below but needs to 
    // be a consideration if refactored.
    //
    // When the app is in the background it isn't always notified of changes that affect the availability of the 
    // service so always check when the app becomes active.
    //
    func applicationDidBecomeActive(application: UIApplication) {
        println("Application did become active")
        TagNotification.dismissAll()
        serviceAvailabilityMonitor.checkAvailability()
        if serviceAvailabilityMonitor.isAvailable {
            initUI()
        } else {
            let reason = serviceAvailabilityMonitor.getMostRelevantHumanErrorMessage()
            assert(reason, "Failed to get reason for service unavailability")
            mainView.presentServiceUnavailable(reason!)
        }
    }
    
    // Initialise the user interface based on the current state of the zone.
    //
    func initUI() {
        if let tagActive = zoneManager.getActiveTag() {
            println("Showing tag view")
            zoneManager.stopMonitoringLocationChanges()
            mainView.presentTagView(tagActive, server: server, delegate: self)
        } else {
            println("Showing create view")
            mainView.presentTagCreate(zoneManager, server: server, delegate: self)
        }
    }
    
    // Handle app resigning active state.
    //
    // The app must be listening for significant location updates as it transitions to a background state because this 
    // uses less power and also means that if the app is killed by the OS it will be relaunched in response to 
    // significant location update.
    //
    // When the app is woken the UI should be empty and built from scratch. In preparation for this remove any view 
    // from the main controller. This isn't animated because at this point it's invisible to the user and this method 
    // must complete fast to avoid the app from being killed by the OS.
    //
    // If the service isn't available when resigning active state there is no point attempting to monitor for 
    // significant location updates or update the UI.
    //
    func applicationWillResignActive(application: UIApplication) {
        println("Application will resign active")
        if !serviceAvailabilityMonitor.isAvailable {
            return
        }
        zoneManager.startMonitoringSignificantLocationChanges()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        println("Application will terminate")
        storeManager.saveContext()
    }

    // Handle the user submitting a request to the server to create a new tag.
    //
    // If the app is in the background when this message is received ignore it because we don't want to stop monitoring 
    // for significant location updates and there is no point in updating the UI. Although this is unlikely in this 
    // handler because the latency between the user submitting a request and this delegate receiving the message 
    // doesn't leave much of an opportunity for the app to be made inactive.
    //
    func tagCreationWasSubmitted() {
        if UIApplication.sharedApplication().applicationState != .Active {
            return
        }
        mainView.presentPending()
    }

    // Handle the user successfully creating a tag.
    //
    // If the app is in the background when this message is received ignore it because we don't want to stop monitoring 
    // for significant location updates and there is no point in updating the UI.
    //
    func tagCreationDidSucceed() {
        if UIApplication.sharedApplication().applicationState != .Active {
            return
        }
        zoneManager.stopMonitoringLocationChanges()
        mainView.presentTagCreationSuccess()
    }

    // Handle an error occurring when the user tried to create a tag.
    //
    // If the app is in the background when this message is received ignore it because we don't want to stop monitoring 
    // for significant location updates and there is no point in updating the UI.
    //
    func tagCreationDidFail() {
        if UIApplication.sharedApplication().applicationState != .Active || !serviceAvailabilityMonitor.isAvailable {
            return
        }
        zoneManager.stopMonitoringLocationChanges()
        mainView.presentServerError()
    }

    // Handle the user submitting a request to the server to acknowledge a tag.
    //
    func tagAcknowledgementWasSubmitted() {
        if UIApplication.sharedApplication().applicationState != .Active || !serviceAvailabilityMonitor.isAvailable {
            return
        }
        mainView.presentPending()
    }
    
    // Handle the user successfully acknowledging a tag.
    //
    func tagAcknowledgementDidSucceed(tagID: String) {
        zoneManager.removeTag(tagID)
        if UIApplication.sharedApplication().applicationState != .Active || !serviceAvailabilityMonitor.isAvailable {
            return
        }
        initUI()
    }
    
    // Handle an error occurring when the user tried to acknowledge a tag.
    //
    func tagAcknowledgementDidFail() {
        if UIApplication.sharedApplication().applicationState != .Active || !serviceAvailabilityMonitor.isAvailable {
            return
        }
        zoneManager.stopMonitoringLocationChanges()
        mainView.presentServerError()
    }

    // Handle the device entering a tag geofence.
    //
    // If the app is in the background dispatch a notification, otherwise take no action. The Zone Manager will have
    // already updated the necessary resources in response to this event.
    //
    func didEnterTagRegion(tag: Tag) {
        if UIApplication.sharedApplication().applicationState != .Background {
            return
        }
        println("Dispatching local notification \(tag.id)")
        dispatch_async(dispatch_get_main_queue()) {
            TagNotification.present(tag)
        }
    }

    // Handle the device exiting a tag geofence.
    //
    // In theory this event can be ignored if the app is running in the foreground because notifications are cleared when
    // the app is launched by the user. For simplicity, and to be safe, notifications are dismissed regardless of app
    // state.
    //
    func didExitTagRegion(tag: Tag) {
        dispatch_async(dispatch_get_main_queue()) {
            TagNotification.dismissIfPresenting(tag)
        }
    }
    
    // Respond to the service becoming available.
    //
    // If the app is active then load the user interface from the zone (which at this point should be empty). If the 
    // app is in the background then resume monitoring for significant location updates.
    //
    func serviceDidBecomeAvailable() {
        if UIApplication.sharedApplication().applicationState == .Active {
            initUI()
        } else {
            zoneManager.startMonitoringSignificantLocationChanges()
        }
    }

    func serviceDidBecomeUnavailable() {
        zoneManager.offline()
        if UIApplication.sharedApplication().applicationState == .Active {
            let reason = serviceAvailabilityMonitor.getMostRelevantHumanErrorMessage()
            assert(reason, "Failed to get reason for service unavailability")
            mainView.presentServiceUnavailable(reason!)
        }
    }
    
    // Once the device has been registered with Apple Push Notification Services post the device ID to the server.
    //
    // The device token is originally an NSData object which needs to be converted and formatted as an NSString for
    // compatibility with the server.
    //
    func application(
            application: UIApplication!, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData!) {
        
        let deviceTokenString = deviceToken.description.stringByReplacingOccurrencesOfString(
            " ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        server.registerDeviceForPushNotification(
            deviceTokenString,
            success: {
                println("Successfully registered device with server")
            },
            error: { e in
                println("Failed to register device with server")
            }
        )
    }

    func application(application: UIApplication!, didReceiveRemoteNotification userInfo: NSDictionary!) {
        println("Received tag acknowledgement notification")
    }

    func application(application: UIApplication!, didFailToRegisterForRemoteNotificationsWithError error: NSError!) {
        println("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

