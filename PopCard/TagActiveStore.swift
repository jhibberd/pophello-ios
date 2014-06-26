import CoreData

class TagActiveStore {
    
    let ENTITY_NAME = "TagActive"
    let storeManager: StoreManager
    
    init(storeManager: StoreManager) {
        self.storeManager = storeManager
    }
    
    // Put the active tag into the store, replacing any existing tag.
    //
    func put(tag: Tag) {
        clear()
        let object = NSEntityDescription.insertNewObjectForEntityForName(
            ENTITY_NAME, inManagedObjectContext: storeManager.getManagedObjectContext()) as NSManagedObject
        object.setValue(tag.id, forKey: "id")
        object.setValue(tag.latitude, forKey: "lat")
        object.setValue(tag.longitude, forKey: "lng")
        object.setValue(tag.text, forKey: "text")
        object.setValue(tag.userID, forKey: "user_id")
        object.setValue(tag.userImageURL, forKey: "user_image_url")
        storeManager.saveContext()
    }
    
    func fetch() -> Tag? {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(
            ENTITY_NAME, inManagedObjectContext: storeManager.getManagedObjectContext())
        var error: NSError?
        let fetchedObjects = storeManager.getManagedObjectContext().executeFetchRequest(
            fetchRequest, error: &error) as NSManagedObject[]
        if let error = error {
            println(error.localizedDescription)
            return nil
        }
        if fetchedObjects.isEmpty {
            return nil
        }
        return makeTagFromManagedObject(fetchedObjects[0])
    }
    
    func clearIfActive(tagID: String) {
        let tagActive = fetch()
        if let tag = tagActive {
            if tag.id == tagID {
                clear()
            }
        } else {
            println("Attempting to clear active tag from empty store")
        }
    }
    
    func clear() {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(
            ENTITY_NAME, inManagedObjectContext: storeManager.getManagedObjectContext())
        fetchRequest.includesPropertyValues = false
        var error: NSError?
        let fetchedObjects = storeManager.getManagedObjectContext().executeFetchRequest(
            fetchRequest, error: &error) as NSManagedObject[]
        if let error = error {
            println(error.localizedDescription)
            return
        }
        for object in fetchedObjects {
            storeManager.getManagedObjectContext().deleteObject(object)
        }
        storeManager.saveContext()
    }
    
    func makeTagFromManagedObject(object: NSManagedObject) -> Tag {
        return Tag(
            id: object.valueForKey("id") as String,
            latitude: object.valueForKey("lat") as Double,
            longitude: object.valueForKey("lng") as Double,
            text: object.valueForKey("text") as String,
            userID: object.valueForKey("user_id") as String,
            userImageURL: object.valueForKey("user_image_url") as String
        )
    }
}