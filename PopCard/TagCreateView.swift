import CoreLocation
import UIKit

protocol TagCreateViewDelegate {
    func tagCreationWasSubmitted()
    func tagCreationDidSucceed()
    func tagCreationDidFail()
}

protocol TagCreateViewAlertDelegate {
    func tagCreationFailedNoLocation()
}

// Display an interface that allows the user to compose a new card.
//
class TagCreateView: UIView {

    let userView: UserView!
    let textView = UITextView()
    let button = ActionButton()
    let zoneManager: ZoneManager
    let server: Server
    let delegate: TagCreateViewDelegate?
    let delegate2: TagCreateViewAlertDelegate?
    
    init(zoneManager: ZoneManager, server: Server, delegate: TagCreateViewDelegate,
            delegate2: TagCreateViewAlertDelegate) {
        self.zoneManager = zoneManager
        self.server = server
        self.delegate = delegate
        self.delegate2 = delegate2
        self.userView = nil
        super.init(frame: CGRectNull) // auto layout
        self.userView = makeUserView()
        backgroundColor = Palette.contentBackgroundColor
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
        textView.font = Font.primaryFont
        textView.backgroundColor = Palette.contentBackgroundColor
        textView.textColor = Palette.mainTextColor
        textView.textContainer.lineFragmentPadding = 15 // to match UILabel padding
        textView.scrollEnabled = false // otherwise layout constraint don't work
        textView.becomeFirstResponder()
        textView.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(textView)
    }
    
    func initButton() {
        button.titleLabel.font = Font.primaryFont
        button.setTitleColor(Palette.buttonTextColor, forState: .Normal)
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
            delegate2?.tagCreationFailedNoLocation()
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