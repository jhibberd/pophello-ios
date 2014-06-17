import CoreLocation
import UIKit

// Display an interface that allows the user to compose a new card.
//
class TagCreateView: UIView {

    let userView: UserView!
    let textView = UITextView()
    let button = ActionButton()
    let zoneManager: ZoneManager
    let server: Server
    let delegate: TagCreateViewDelegate?
    
    init(zoneManager: ZoneManager, server: Server, delegate: TagCreateViewDelegate) {
        self.zoneManager = zoneManager
        self.server = server
        self.delegate = delegate
        self.userView = nil
        super.init(frame: CGRectNull) // auto layout
        self.userView = makeUserView()
        backgroundColor = UIColor.ph_contentBackgroundColor()
        initUserView()
        initTextView()
        initButton()
        initAutoLayout()
    }
    
    func makeUserView() -> UserView {
        let bundle = NSBundle.mainBundle()
        let name = bundle.objectForInfoDictionaryKey("UserID") as String
        let imageURL = bundle.objectForInfoDictionaryKey("UserImageURL") as String
        return UserView(name: name, imageURL: imageURL)
    }
    
    func initUserView() {
        userView.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(userView)
    }
    
    func initTextView() {
        textView.font = UIFont.ph_primaryFont()
        textView.backgroundColor = UIColor.ph_contentBackgroundColor()
        textView.textColor = UIColor.ph_mainTextColor()
        textView.textContainer.lineFragmentPadding = 15 // to match UILabel padding
        textView.scrollEnabled = false // otherwise layout constraint don't work
        textView.becomeFirstResponder()
        textView.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(textView)
    }
    
    func initButton() {
        button.titleLabel.font = UIFont.ph_primaryFont()
        button.setTitleColor(UIColor.ph_buttonTextColor(), forState: .Normal)
        button.setTitle(NSLocalizedString("TAG_CREATE_SUBMIT", comment: ""), forState: .Normal)
        button.addTarget(self, action: "onButtonClick", forControlEvents: .TouchUpInside)
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(button)
    }
    
    func initAutoLayout() {
        let bindings = ["userView": userView, "textView": textView, "button": button]
        let formats = [
            "V:|-30-[userView]-50-[textView]-(>=15)-[button(55)]|",
            "|[textView]|",
            "|-15-[userView]-15-|",
            "|[button]|"]
        for fmt in formats {
            let constraints = NSLayoutConstraint.constraintsWithVisualFormat(
                fmt, options: .DirectionLeadingToTrailing, metrics: nil, views: bindings)
            addConstraints(constraints)
        }
    }
    
    func onButtonClick() {
        
        let text = textView.text
        if text.isEmpty {
            return
        }
        
        let location = zoneManager.getLastPreciseLocation()
        if !CLLocationCoordinate2DIsValid(location) {
            let alert = UIAlertView(
                title: "PopHello",
                message: NSLocalizedString("LOCATION_UNKNOWN", comment: ""),
                delegate: nil,
                cancelButtonTitle: NSLocalizedString("OK", comment: ""))
            alert.show()
            return
        }
        
        textView.editable = false
        button.enabled = false
        delegate?.tagCreationWasSubmitted()
        server.postTagAt(location,
            text: text,
            success: { [unowned self] in
                dispatch_async(dispatch_get_main_queue()) {
                    print() // without this compilation fails!
                    self.delegate?.tagCreationDidSucceed()
                }
            },
            error: { [unowned self] e in
                dispatch_async(dispatch_get_main_queue()) {
                    print() // without this compilation fails!
                    self.delegate?.tagCreationDidFail()
                }
            }
        )
    }
}