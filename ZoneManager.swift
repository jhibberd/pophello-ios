import CoreLocation
import Foundation

// TODO: remove base class
class ZoneManager: NSObject {
    
    func getLastPreciseLocation() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(1, 1)
    }
}