import CoreLocation

class Server: NSObject {

    let PROPERY_SERVER_HOST = "ServerHost"
    let userID: String
    
    // All calls to the server take place within the context of a user.
    //
    init(userID: String) {
        self.userID = userID
    }

    // Return data for a set of tags near the current device's location.
    //
    func queryForZoneTags(center: CLLocationCoordinate2D, success: (Tag[]) -> (), error: (NSDictionary?) -> ()) {
        let query = "lat=\(center.latitude)&lng=\(center.longitude)&user_id=\(userID)"
        let url = buildURLWithPath("/tags", query: query)
        let request = NSMutableURLRequest(URL: url)
        dataTaskWithRequest(request, success: { payload in
            var tags = Tag[]()
            for tagData: NSDictionary in payload["data"] as NSDictionary[] {
                tags.append(Tag(JSON: tagData))
            }
            success(tags)
            }, error: { e in error(e) })
    }

    // Post a new tag at the device's current location.
    //
    func postTagAt(center: CLLocationCoordinate2D, text: String, success: () -> (), error: (NSDictionary?) -> ()) {
        let body = ["user_id": userID, "lat": center.latitude, "lng": center.longitude, "text": text]
        let url = buildURLWithPath("/tags", query: nil)
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = serializePayload(body)
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-type")
        dataTaskWithRequest(request, success: { _ in success() }, error: { e in error(e) })
    }
    
    // Acknowledge that the user has consumed a tag. The user won't be presented with the tag again and the author will 
    // be notified.
    //
    func acknowledgeTag(tagID: String, success: () -> (), error: (NSDictionary?) -> ()) {
        let query = "user_id=\(userID)"
        let path = "/tags/\(tagID)"
        let url = buildURLWithPath(path, query: query)
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "DELETE"
        dataTaskWithRequest(request, success: { _ in success() }, error: { e in error(e) })
    }
    
    // Once a device has registered with Apple Push Notification Services post its device ID to the server so that it 
    // can receive push notifications. Currently push notifications are only used to notify a user that one of their 
    // tags has been discovered by another user.
    //
    func registerDeviceForPushNotification(deviceID: String, success: () -> (), error: (NSDictionary?) -> ()) {
        let body = ["user_id": userID, "device_id": deviceID, "device_type": "apple"]
        let url = buildURLWithPath("/devices", query: nil)
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = serializePayload(body)
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-type")
        dataTaskWithRequest(request, success: { _ in success() }, error: { e in error(e) })
    }
    
    // Issue an HTTP request asynchronously returning the result as a Dictionary to a success or error callback.
    //
    func dataTaskWithRequest(request: NSURLRequest, success: (NSDictionary) -> (), error: (NSDictionary?) -> ()) {
        println("Server request \(request.HTTPMethod) \(request.URL)")
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: {
            (data: NSData!, response: NSURLResponse!, taskError: NSError!) in
            let statusCode = (response as NSHTTPURLResponse).statusCode
            println("Server response status code: \(statusCode)")
            if taskError {
                println("Server response is error: \(taskError.localizedDescription)")
            } else {
                var deserializeError: NSError?
                let payload = NSJSONSerialization.JSONObjectWithData(
                    data, options: nil, error: &deserializeError) as Dictionary<String, AnyObject>
                if deserializeError {
                    let payloadString = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println("Server response not serializable: \(payloadString)")
                    error(nil)
                } else {
                    if statusCode != 200 && statusCode != 201 {
                        println("Server response is error: \(payload)")
                        error(payload)
                    } else {
                        println("Server response is success: \(payload)")
                        success(payload)
                    }
                }
            }
            })
        task.resume()
    }
    
    // Syntactic shortcut for building an NSURL object from a path and optional query string.
    //
    func buildURLWithPath(path: String, query: String?) -> NSURL {
        let bundle = NSBundle.mainBundle()
        let host = bundle.objectForInfoDictionaryKey(PROPERY_SERVER_HOST) as String
        let components = NSURLComponents()
        components.scheme = "http"
        components.host = host
        components.port = 4000
        components.path = path
        if let query = query {
            components.query = query
        }
        return components.URL
    }
    
    func serializePayload(data: NSDictionary) -> NSData {
        var error: NSError?
        let result = NSJSONSerialization.dataWithJSONObject(data, options: nil, error: &error)
        assert(!error, "Failed to serialize HTTP payload")
        return result!
    }
}
