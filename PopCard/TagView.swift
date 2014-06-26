import UIKit

protocol TagViewDelegate {
    func tagAcknowledgementWasSubmitted()
    func tagAcknowledgementDidSucceed(String)
    func tagAcknowledgementDidFail()
}

// Display a tag to the user.
//
class TagView: UIView {
    
    let card: Tag
    let userview: UserView
    let label = UILabel()
    let button = ActionButton()
    let server: Server
    let delegate: TagViewDelegate?
    
    init(card: Tag, server: Server, delegate: TagViewDelegate?) {
        self.card = card
        self.server = server
        self.delegate = delegate
        self.userview = UserView(name: card.userID, imageURL: card.userImageURL)
        super.init(frame: CGRectNull) // auto layout
        backgroundColor = Palette.contentBackgroundColor
        initUserView()
        initLabel()
        initButton()
        initAutoLayout()
    }
    
    func initUserView() {
        userview.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(userview)
    }
    
    func initLabel() {
        label.font = Font.primaryFont
        label.backgroundColor = Palette.contentBackgroundColor
        label.textColor = Palette.mainTextColor
        label.numberOfLines = 0
        label.text = card.text
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(label)
    }
    
    func initButton() {
        button.titleLabel.font = Font.primaryFont
        button.setTitleColor(Palette.buttonTextColor, forState: .Normal)
        button.setTitle(NSLocalizedString("TAG_ACKNOWLEDGE", comment: ""), forState: .Normal)
        button.addTarget(self, action: "onButtonClick", forControlEvents: .TouchUpInside)
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(button)
    }
    
    func initAutoLayout() {
        let bindings = ["userview": userview, "label": label, "button": button]
        let formats = [
            "V:|-30-[userview]-50-[label]-(>=15)-[button(55)]|",
            "|-15-[label]-15-|",
            "|-15-[userview]-15-|",
            "|[button]|"]
        for fmt in formats {
            let constraints = NSLayoutConstraint.constraintsWithVisualFormat(
                fmt, options: .DirectionLeadingToTrailing, metrics: nil, views: bindings)
            addConstraints(constraints)
        }
    }
    
    func onButtonClick() {
        button.enabled = false
        delegate?.tagAcknowledgementWasSubmitted()
        server.acknowledgeTag(
            card.id,
            success: { [unowned self] in
                dispatch_async(dispatch_get_main_queue()) {
                    print() // without this compilation fails!
                    self.delegate?.tagAcknowledgementDidSucceed(self.card.id)
                }
            },
            error: { [unowned self] e in
                dispatch_async(dispatch_get_main_queue()) {
                    print() // without this compilation fails!
                    self.delegate?.tagAcknowledgementDidFail()
                }
            }
        )
    }
}
