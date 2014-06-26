import UIKit

class TagNotification {
    
    // Present a tag local notification.
    //
    // Used when the device touches a tag region and the app is running in the background. Only one tag local 
    // notification should be visible at once (representing the most recently touched tag). Since the old local 
    // notifications that this app presents are tag notifications it's sufficient to dismiss all existing local 
    // notifications before presenting a new notification. This is more robust that maintaining a memory reference to 
    // the visible UILocalNotification object which would be lost if the app was terminated.
    //
    class func present(tag: Tag) {
        dismissAll()
        let notification = makeLocalNotificationFromTag(tag)
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
    // Dismiss a tag local notification if it's currently being presented.
    //
    // Used when the device leaves a tag region.
    //
    // Calling `cancelLocalNotification` with a notification that isn't (or has never been) visible is harmless. 
    // Creating a new UILocalNotification object with the same properties as a different, visible UILocalNotification 
    // object and then using it to call `cancelLocalNotification` will result in the visible notification being matched 
    // and cancelled. This is more robust that maintaining a memory reference to the visible UILocalNotification object 
    // which would be lost if the app was terminated.
    //
    class func dismissIfPresenting(tag: Tag) {
        let notification = makeLocalNotificationFromTag(tag)
        UIApplication.sharedApplication().cancelLocalNotification(notification)
    }
    
    // Dismiss all tag local notifications.
    //
    // Used when the app is launched by the user (and not the OS, eg. as a result of a location update). Local
    // notifications are a means to attract the user to the app. Once the app has been launched they have served their
    // purpose.
    //
    class func dismissAll() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    class func makeLocalNotificationFromTag(tag: Tag) -> UILocalNotification {
        let notification = UILocalNotification()
        notification.alertBody = "\(tag.userID): \(tag.text)"
        notification.soundName = UILocalNotificationDefaultSoundName
        return notification
    }
}