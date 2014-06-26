import CoreLocation
import UIKit

enum LocationUpdateMode {
    case None
    case Significant
    case Precise
}

protocol ZoneManagerDelegate {
    func didEnterTagRegion(Tag)
    func didExitTagRegion(Tag)
}

class ZoneManager: LocationServiceDelegate {
    
    let locationService: LocationService
    let server: Server
    let tagsStore: TagsStore
    let tagActiveStore: TagActiveStore
    let delegate: ZoneManagerDelegate?
    var lastPreciseLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var backgroundTaskQueryServer: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var locationUpdateMode: LocationUpdateMode = .None
    var isOffline = true
    
    init(storeManager: StoreManager, locationService: LocationService, server: Server,
            delegate: ZoneManagerDelegate?) {
        self.locationService = locationService
        self.server = server
        self.tagsStore = TagsStore(storeManager: storeManager)
        self.tagActiveStore = TagActiveStore(storeManager: storeManager)
        self.delegate = delegate
    }
    
    func startMonitoringSignificantLocationChanges() {
        isOffline = false
        switch locationUpdateMode {
        case .Precise:
            stopMonitoringPreciseLocationChanges()
        case .Significant:
            return
        case .None:
            break
        }
        locationService.startMonitoringSignificantLocationChanges()
        locationUpdateMode = .Significant
    }
    
    func startMonitoringPreciseLocationChanges() {
        isOffline = false
        switch locationUpdateMode {
        case .Precise:
            return
        case .Significant:
            break
        case .None:
            break
        }
        locationService.startMonitoringPreciseLocationChanges()
        locationUpdateMode = .Precise
    }
    
    func stopMonitoringLocationChanges() {
        isOffline = false
        switch locationUpdateMode {
        case .Precise:
            stopMonitoringPreciseLocationChanges()
        case .Significant:
            break
        case .None:
            return
        }
        locationService.stopMonitoringLocation()
        locationUpdateMode = .None
    }
    
    func stopMonitoringPreciseLocationChanges() {
        lastPreciseLocation = kCLLocationCoordinate2DInvalid
    }
    
    func getLastPreciseLocation() -> CLLocationCoordinate2D {
        return lastPreciseLocation
    }
    
    func getActiveTag() -> Tag? {
        return tagActiveStore.fetch()
    }
    
    func removeTag(tagID: String) {
        tagActiveStore.clearIfActive(tagID)
        tagsStore.remove(tagID)
        locationService.removeGeofence(tagID)
    }
    
    // Stop all activity and clear all state.
    //
    // This happens in response to the service becoming unavailable. After calling this method the only part of the 
    // ZoneManager that may still be active is a pending server request. The request callback first checks whether the 
    // ZoneManager is still online before processing the server response.
    //
    func offline() {
        isOffline = true
        stopMonitoringLocationChanges()
        locationService.removeAllGeofences()
        tagActiveStore.clear()
        tagsStore.clear()
    }
    
    // The device received a significant location update to establish a new zone.
    //
    func deviceDidUpdateSignificantLocation(center: CLLocationCoordinate2D) {
        
        println("Establishing zone at \(center.latitude), \(center.longitude)")
        let app = UIApplication.sharedApplication()
        backgroundTaskQueryServer = app.beginBackgroundTaskWithExpirationHandler {[unowned self] in
            // must exit quickly to prevent the app being killed by the OS
            println("Failed to establish zone within allocated background time.")
            app.endBackgroundTask(self.backgroundTaskQueryServer)
            self.backgroundTaskQueryServer = UIBackgroundTaskInvalid
        }
        assert(backgroundTaskQueryServer != UIBackgroundTaskInvalid, "Background tasks unavailable on device")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {[unowned self] in
            let taskID = self.backgroundTaskQueryServer
            self.server.queryForZoneTags(center,
                success: { tags in
                    if taskID != self.backgroundTaskQueryServer {
                        println("Dismissing server response because a new query has been issued")
                    } else if self.isOffline {
                        println("Dismissing server response because service is offline")
                    } else {
                        self.updateZoneWithTags(tags, center: center)
                    }
                },
                error: { e in
                    println("Server error while establishing zone")
                    app.endBackgroundTask(self.backgroundTaskQueryServer)
                    self.backgroundTaskQueryServer = UIBackgroundTaskInvalid
                }
            )
        }
    }
    
    func updateZoneWithTags(tagsNew: Tag[], center: CLLocationCoordinate2D) {
        let tagsOld = tagsStore.fetchAll()
        tagsStore.clear()
        tagsStore.put(tagsNew)
        let tagActive = tagActiveStore.fetch()
        let keepTagActive = tagActive && TagListUtil.contains(tagActive!.id, tags: tagsNew)
        if !keepTagActive && tagActive != nil {
            tagActiveStore.clear()
            dispatch_async(dispatch_get_main_queue()) {
                TagNotification.dismissAll()
            }
        }
        locationService.updateGeofencesFromTags(tagsOld, tagsNew:tagsNew)
        if (!keepTagActive) {
            locationService.triggerEnterTagRegionForFirstTagContainingCoordinate(center)
        }
    }
    
    func deviceDidUpdatePreciseLocation(center: CLLocationCoordinate2D) {
        lastPreciseLocation = center
    }
    
    func didEnterTagRegion(tagID: String) {
        let tag = tagsStore.fetch(tagID)
        if let tag = tag {
            tagActiveStore.put(tag)
            delegate?.didEnterTagRegion(tag)
        } else {
            println("Entered region for unknown tag")
        }
    }
    
    func didExitTagRegion(tagID: String) {
        let tag = tagsStore.fetch(tagID)
        if let tag = tag {
            tagActiveStore.clearIfActive(tagID)
            delegate?.didExitTagRegion(tag)
        } else {
            println("Existed region for unknown tag")
        }
    }
}