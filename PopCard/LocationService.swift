import CoreLocation

@class_protocol protocol LocationServiceDelegate {
    func deviceDidUpdateSignificantLocation(center: CLLocationCoordinate2D)
    func deviceDidUpdatePreciseLocation(center: CLLocationCoordinate2D)
    func didEnterTagRegion(tagID: String)
    func didExitTagRegion(tagID: String)
}

// Wrapper around CLLocationManager.
//
class LocationService: NSObject, CLLocationManagerDelegate {
    
    let TAG_REGION_RADIUS: Double = 100
    let locationManager: CLLocationManager
    let serviceAvailabilityMonitor: ServiceAvailabilityMonitor
    weak var delegate: LocationServiceDelegate? // to avoid strong reference cycle with ZoneManager
    var locationUpdateMode: LocationUpdateMode
    
    init(serviceAvailabilityMonitor: ServiceAvailabilityMonitor) {
        self.locationManager = CLLocationManager()
        self.serviceAvailabilityMonitor = serviceAvailabilityMonitor
        self.locationUpdateMode = .None
        super.init()
        self.locationManager.delegate = self
    }
    
    // Start monitoring significant location updates using low power.
    //
    // Used to refresh the current zone while the app is in the background. Location updates will not be received
    // unless the device moves roughly 500 meters, and no more than one every 5 minutes.
    //
    func startMonitoringSignificantLocationChanges() {
        println("Started monitoring significant location changes")
        switch locationUpdateMode {
        case .None:
            break
        case .Precise:
            stopMonitoringPreciseLocationChanges()
        case .Significant:
            return
        }
        locationManager.startMonitoringSignificantLocationChanges()
        locationUpdateMode = .Significant
    }
    
    // Start monitoring precise location updates using high power.
    //
    // Used to get the device's precise location while a tag is being composed. The default values for `distanceFilter` 
    // and `desiredAccuracy` already provide the greatest precision.
    //
    func startMonitoringPreciseLocationChanges() {
        println("Started monitoring precise location changes")
        switch locationUpdateMode {
        case .None:
            break
        case .Precise:
            return
        case .Significant:
            stopMonitoringSignificantLocationChanges()
        }
        locationManager.startUpdatingLocation()
        locationUpdateMode = .Precise
    }
    
    func stopMonitoringLocation() {
        println("Stopped monitoring location changes")
        switch locationUpdateMode {
        case .None:
            return
        case .Precise:
            stopMonitoringPreciseLocationChanges()
        case .Significant:
            stopMonitoringSignificantLocationChanges()
        }
        locationUpdateMode = .None
    }
    
    func stopMonitoringSignificantLocationChanges() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    func stopMonitoringPreciseLocationChanges() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: AnyObject[]!) {
        let location = locations[locations.endIndex - 1] as CLLocation
        let age = location.timestamp.timeIntervalSinceNow
        println("Location update \(location.coordinate.latitude), \(location.coordinate.longitude) accuracy=\(location.horizontalAccuracy) age=\(age)")
        switch locationUpdateMode {
        case .None:
            break
        case .Significant:
            delegate?.deviceDidUpdateSignificantLocation(location.coordinate)
        case .Precise:
            delegate?.deviceDidUpdatePreciseLocation(location.coordinate)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("Location update failed: \(error.localizedDescription)")
    }
    
    func locationManagerDidPauseLocationUpdates(manager: CLLocationManager!) {
        println("Location updating was paused")
    }
    
    func locationManagerDidResumeLocationUpdates(manager: CLLocationManager!) {
        println("Location updating was resumed")
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        serviceAvailabilityMonitor.locationAuthorizationStatusDidChange(status)
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        println("Region entered: \(region.identifier)")
        delegate?.didEnterTagRegion(region.identifier) // tag ID
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        println("Region exited: \(region.identifier)")
        delegate?.didExitTagRegion(region.identifier) // tag ID
    }
    
    func locationManager(
            manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
        serviceAvailabilityMonitor.regionMonitoringDidFail(error)
    }
    
    func updateGeofencesFromTags(tagsOld: Tag[], tagsNew: Tag[]) {
        println("Updating geofences")
        
        let tagsExpired = TagListUtil.relativeComplement(tagsOld, a: tagsNew)
        // XCode doesn't like iterating over NSSet
        for region in locationManager.monitoredRegions.allObjects as CLRegion[] {
            
            if TagListUtil.contains(region.identifier, tags: tagsExpired) {
                println("Deleting geofence: \(region.identifier)")
                locationManager.stopMonitoringForRegion(region)
                continue
            }
            
            // this shouldn't happen but it does, so worth handling/logging
            if !TagListUtil.contains(region.identifier, tags: tagsOld) {
                println("Deleting unknown geofence: \(region.identifier)")
                locationManager.stopMonitoringForRegion(region)
                continue
            }
        }
        
        let tagsRevealed = TagListUtil.relativeComplement(tagsNew, a: tagsOld)
        for tag in tagsRevealed {
            let center = CLLocationCoordinate2DMake(tag.latitude, tag.longitude)
            let region = CLCircularRegion(center: center, radius: TAG_REGION_RADIUS, identifier: tag.id)
            locationManager.stopMonitoringForRegion(region)
            println("Created geofence: \(region.identifier)")
        }
    }
    
    func removeGeofence(tagID: String) {
        // XCode doesn't like iterating over NSSet
        for region in locationManager.monitoredRegions.allObjects as CLRegion[] {
            if region.identifier == tagID {
                locationManager.stopMonitoringForRegion(region)
                return
            }
        }
        println("Attempted to remove geofence which didn't exist: \(tagID)")
    }
    
    func removeAllGeofences() {
        // XCode doesn't like iterating over NSSet
        for region in locationManager.monitoredRegions.allObjects as CLRegion[] {
            locationManager.stopMonitoringForRegion(region)
        }
    }
    
    // Check whether any tags contain the current device and dispatch a geofence enter event if they do.
    //
    // Core Location doesn't trigger a region boundary crossing if the device is currently inside the geofence when 
    // it's created. CLLocationManager exposes the method `requestStateForRegion:` which tests whether the device is 
    // currently in a given geofence, but only works on geofences that are sublasses of Map Kit classes. Android does 
    // this automatically. Only the first tag geofence to contain the coordinate triggers the event.
    //
    func triggerEnterTagRegionForFirstTagContainingCoordinate(coordinate: CLLocationCoordinate2D) {
        // XCode doesn't like iterating over NSSet
        for region in locationManager.monitoredRegions.allObjects as CLRegion[] {
            if region.containsCoordinate(coordinate) {
                delegate?.didEnterTagRegion(region.identifier)
                return
            }
        }
    }
}