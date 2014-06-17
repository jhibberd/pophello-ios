import UIKit

// Display a user's name and profile picture.
//
class UserView: UIView {

    let USER_IMAGE_SIZE: Float = 60
    
    init(name: String, imageURL: String) {
        super.init(frame: CGRectNull) // auto layout
        
        let url = NSURL(string: imageURL)
        let placeholder = createPlaceholderImage()
        let avatar = UIImageView(image: placeholder)
        addSubview(avatar)
        
        let label = UILabel()
        label.text = name
        label.font = UIFont.ph_usernameFont()
        label.textColor = UIColor.ph_mainTextColor()
        label.backgroundColor = UIColor.ph_contentBackgroundColor()
        addSubview(label)
        
        avatar.setTranslatesAutoresizingMaskIntoConstraints(false)
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        let bindings = ["avatar": avatar, "label": label]
        for fmt in ["V:|[avatar(\(USER_IMAGE_SIZE))]-5-[label]|",
                    "|[avatar(\(USER_IMAGE_SIZE))]-(>=0)-|",
                    "|[label]|"] {
            let constraints = NSLayoutConstraint.constraintsWithVisualFormat(
                fmt, options: .DirectionLeadingToTrailing, metrics: nil, views: bindings)
            addConstraints(constraints)
        }
        
        // async load the profile image from Facebook
        var q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(q) {
            let data = NSData(contentsOfURL: url)
            let img = UIImage(data: data)
            dispatch_async(dispatch_get_main_queue()) {
                avatar.image = img;
                }
            }
    }
    
    // Create a placeholder image consisting of a solid color.
    //
    func createPlaceholderImage() -> UIImage {
        let rect = CGRectMake(0, 0, USER_IMAGE_SIZE, USER_IMAGE_SIZE)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0);
        UIColor.ph_userImagePlaceholderColor().setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image
    }
}
