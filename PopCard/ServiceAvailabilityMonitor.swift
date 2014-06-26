import CoreLocation
import UIKit

protocol ServiceAvailabilityMonitorDelegate {
    func serviceDidBecomeAvailable()
    func serviceDidBecomeUnavailable()
}

class ServiceAvailabilityMonitor {
    
    var isRegionMonitoringSupportedByDevice: Bool
    var isMultitaskingSupportedByDevice: Bool
    var isBackgroundAppRefreshAvailable: Bool
    var isRegionMonitoringAvailable: Bool
    var isLocationServicesAuthorized: Bool
    var isLocationServicesEnabled: Bool
    var isLocalStorageAvailable: Bool
    
    var isAvailable: Bool
    let delegate: ServiceAvailabilityMonitorDelegate
    
    init(delegate: ServiceAvailabilityMonitorDelegate) {
        
        self.delegate = delegate
        
        // checked initially
        isRegionMonitoringSupportedByDevice = false
        isMultitaskingSupportedByDevice = false
        isBackgroundAppRefreshAvailable = false
        isLocationServicesAuthorized = false
        isLocationServicesEnabled = false
        
        // assumed to be working unless a failure is reported
        isRegionMonitoringAvailable = true
        isLocalStorageAvailable = true
        
        isAvailable = false
        
        // subscribe to settings changes
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "backgroundRefreshStatusDidChange:",
            name: UIApplicationBackgroundRefreshStatusDidChangeNotification,
            object: nil)
    }
    
    // If the service is unavailable return the most relevant human-friendly error message to be display in the main UI.
    //
    // A relevant error message will be a message that relates to a missing feature that a user has influence over, as
    // opposed to an error for a missing feature not supported by the device.
    //
    func getMostRelevantHumanErrorMessage() -> String? {
        
        // setting the user can probably change
        if !isLocationServicesAuthorized {
            return NSLocalizedString("SERVICE_UNAVAILABLE_IS_LOCATION_SERVICES_AUTHORIZED", comment: "");
        }
        if !isLocationServicesEnabled {
            return NSLocalizedString("SERVICE_UNAVAILABLE_IS_LOCATION_SERVICES_ENABLED", comment: "");
        }
        if !isBackgroundAppRefreshAvailable {
            return NSLocalizedString("SERVICE_UNAVAILABLE_IS_BACKGROUND_APP_REFRESH_AVAILABLE", comment: "");
        }
        
        // unexpected error
        if !isRegionMonitoringAvailable {
            return NSLocalizedString("SERVICE_UNAVAILABLE_IS_REGION_MONITORING_AVAILABLE", comment: "");
        }
        if !isLocalStorageAvailable {
            return NSLocalizedString("SERVICE_UNAVAILABLE_IS_LOCAL_STORAGE_AVAILABLE", comment: "");
        }
        
        // unsupported device
        if !isRegionMonitoringSupportedByDevice {
            return NSLocalizedString("SERVICE_UNAVAILABLE_IS_REGION_MONITORING_SUPPORTED_BY_DEVICE", comment: "");
        }
        if !isMultitaskingSupportedByDevice {
            return NSLocalizedString("SERVICE_UNAVAILABLE_IS_MULTITASKING_SUPPORT_BY_DEVICE", comment: "");
        }

        return nil
    }
    
    // Perform initial service availability checks when the app is launched.
    //
    func checkAvailability() {
        checkIsRegionMonitoringSupportedByDevice()
        checkIsMultitaskingSupportedByDevice()
        checkIsBackgroundAppRefreshAvailable()
        checkIsLocationServicesAuthorized()
        checkIsLocationServicesEnabled()
        updateAvailabilityAndNotifyDelegateIfChanged(false)
    }
    
    // Region monitoring must be supported by the device for monitoring of tag geofences.
    //
    // The device either supports this feature or doesn't so it won't change.
    //
    func checkIsRegionMonitoringSupportedByDevice() {
        isRegionMonitoringSupportedByDevice = CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion)
    }
    
    // Multitasking must be supported to allow the Zone Manager to update the zone using a background task while the 
    // app is running in the background:
    // https://developer.apple.com/library/ios/documentation/iphone/conceptual/iphoneosprogrammingguide/ManagingYourApplicationsFlow/ManagingYourApplicationsFlow.html#//apple_ref/doc/uid/TP40007072-CH4-SW20
    //
    // The device either supports this feature or doesn't so it won't change.
    //
    func checkIsMultitaskingSupportedByDevice() {
        isMultitaskingSupportedByDevice = UIDevice.currentDevice().multitaskingSupported
    }
    
    // Background App Refresh must be available in order for the app to be launched by the OS in response to a significant
    // location update.
    // https://developer.apple.com/library/ios/documentation/userexperience/conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html
    //
    // This is a setting that can be changed by the user unless the setting is restricted (eg. by parental controls).
    // Monitoring of changes to this setting are handled by `backgroundRefreshStatusDidChange:`.
    //
    func checkIsBackgroundAppRefreshAvailable() {
        isBackgroundAppRefreshAvailable = UIApplication.sharedApplication().backgroundRefreshStatus == .Available
    }
    
    // Location Services must be authorized for this app by the user.
    //
    // If the user hasn't yet determined whether they want to authorize location services for the app assume that they
    // will. The first time location services are requested by the app the user will be prompted. If they reject the
    // request the authorization status will be changed and the UI will be updated accordingly.
    //
    // This is a setting that can be changed by the user unless the setting is restricted (eg. by parental controls).
    // Changes to this user setting are monitored by the app.
    //
    func checkIsLocationServicesAuthorized() {
        let status = CLLocationManager.authorizationStatus()
        isLocationServicesAuthorized = status == .Authorized || status == .NotDetermined
    }
    
    // Location service must be enabled on the device.
    //
    // This is a setting that can be changed by the user. Monitoring of changes to this setting is also handled by
    // `locationAuthorizationStatusDidChange:`.
    //
    func checkIsLocationServicesEnabled() {
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
    }
    
    func updateAvailabilityAndNotifyDelegateIfChanged(notify: Bool) {
        let isAvailableUpdated =
            isRegionMonitoringSupportedByDevice &&
            isMultitaskingSupportedByDevice &&
            isBackgroundAppRefreshAvailable &&
            isRegionMonitoringAvailable &&
            isLocationServicesAuthorized &&
            isLocationServicesEnabled &&
            isLocalStorageAvailable
        let changed = isAvailableUpdated == isAvailable
        isAvailable = isAvailableUpdated
        if changed && notify {
            if isAvailable {
                println("Service did become available")
                delegate.serviceDidBecomeAvailable()
            } else {
                println("Service did become unavailable")
                delegate.serviceDidBecomeAvailable()
            }
        }
    }
    
    // Region monitoring must be supported by the device for monitoring of tag geofences.
    //
    // The CLLocationManager may report that it failed to monitor a geofence/region.
    //
    func regionMonitoringDidFail(error: NSError) {
        println("Region monitoring failed: \(error.localizedDescription)")
        isRegionMonitoringAvailable = false
        updateAvailabilityAndNotifyDelegateIfChanged(true)
    }
    
    // Local storage must be supported to persist tag data.
    //
    // Core Data may report that it failed to read/write data.
    //
    func localStorageDidFail(error: NSError) {
        println("Local storage failed: \(error.localizedDescription)")
        isLocalStorageAvailable = false
        updateAvailabilityAndNotifyDelegateIfChanged(true)
    }
    
    func locationAuthorizationStatusDidChange(status: CLAuthorizationStatus) {
        println("Location authorization status changed: \(status)")
        switch status {
        case .Authorized, .NotDetermined:
            isLocationServicesAuthorized = true
        case .Denied, .Restricted, .AuthorizedWhenInUse:
            isLocationServicesAuthorized = false
        }
        updateAvailabilityAndNotifyDelegateIfChanged(true)
    }
    
    func backgroundRefreshStatusDidChange(notification: NSNotification) {
        isBackgroundAppRefreshAvailable = UIApplication.sharedApplication().backgroundRefreshStatus == .Available
        println("Background App Refresh setting changed: \(isBackgroundAppRefreshAvailable)")
        updateAvailabilityAndNotifyDelegateIfChanged(true)
    }
}