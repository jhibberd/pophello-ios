
class Tag {

    let id: String
    let latitude: Double
    let longitude: Double
    let text: String
    let userID: String
    let userImageURL: String
    
    init(id: String, latitude: Double, longitude: Double, text: String, userID: String, userImageURL: String) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.text = text
        self.userID = userID
        self.userImageURL = userImageURL
    }
}
