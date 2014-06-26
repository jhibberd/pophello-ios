import UIKit

class MainViewController: UIViewController,
        UIGestureRecognizerDelegate, AnimationViewDelegate, TagCreateViewAlertDelegate {

    var animationView: AnimationView!
    var identifierVisible: String?
    var identifierActive: String?
    var viewActive: UIView?
    var isAnimating = false
    
    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
    }
    
    init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = Palette.appBackgroundColor
        
        animationView = AnimationView(delegate: self)
        view.addSubview(animationView)
        
        animationView.setTranslatesAutoresizingMaskIntoConstraints(false)
        let bindings = ["animationView": animationView]
        let formats = [
            "V:|[animationView]|",
            "|[animationView]|"]
        for fmt in formats {
            let constraints = NSLayoutConstraint.constraintsWithVisualFormat(
                fmt, options: .DirectionLeadingToTrailing, metrics: nil, views: bindings)
            view.addConstraints(constraints)
        }
        
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(
            self, selector: "keyboardDidShowOrWillHide:", name: UIKeyboardDidShowNotification, object: nil)
        center.addObserver(
            self, selector: "keyboardDidShowOrWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardDidShowOrWillHide(notification: NSNotification) {
        let userInfo = notification.userInfo
        var keyboardFrameEnd = userInfo[UIKeyboardFrameEndUserInfoKey].CGRectValue()
        keyboardFrameEnd = view.convertRect(keyboardFrameEnd, fromView: nil)
        view.frame = CGRectMake(0, 0, view.frame.size.width, keyboardFrameEnd.origin.y)
        view.layoutIfNeeded()
    }
    
    func presentTagView(card: Tag, server: Server, delegate: TagViewDelegate?) {
        identifierActive = "tag-\(card.id)"
        viewActive = TagView(card: card, server: server, delegate: delegate)
        animateUIToMatchState()
    }
    
    func presentTagCreate(zoneManager: ZoneManager, server: Server, delegate: TagCreateViewDelegate) {
        identifierActive = "tag-creation"
        viewActive = TagCreateView(zoneManager: zoneManager, server: server, delegate: delegate, delegate2: self)
        animateUIToMatchState()
    }
    
    func tagCreationFailedNoLocation() {
        let alert = UIAlertController(
            title: "PopCard",
            message: NSLocalizedString("LOCATION_UNKNOWN", comment: ""),
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentTagCreationSuccess() {
        identifierActive = "tag-creation-success"
        viewActive = TagCreateSuccessView()
        animateUIToMatchState()
    }
    
    func presentServerError() {
        identifierActive = "server-error"
        viewActive = ServerErrorView()
        animateUIToMatchState()
    }
    
    func presentPending() {
        identifierActive = "pending"
        viewActive = PendingView()
        animateUIToMatchState()
    }
    
    func presentServiceUnavailable(reason: String) {
        identifierActive = "service-unavailable"
        viewActive = ServiceUnavailableView(reason: reason)
        animateUIToMatchState()
    }
    
    func presentNothing() {
        identifierActive = nil
        viewActive = nil
        animationView.presentNothingImmediately()
    }
    
    // Animate the UI to match its active state (what it should be displaying).
    //
    // The identifier of the active state is compared with the identifier of the visible state. If both are equal then 
    // the UI is up to date and no further action needs to be taken. An identifier can be nil (displaying nothing), so 
    // these are converted to empty NSString objects to simplify comparison.
    //
    // If the UI is not up to date but an animation is currently in progress then return. When the current animation
    // completes it will check to see whether the UI is up to date, find that it isn't and begin another animation to 
    // the active state.
    //
    // It's safe to modify the `_viewActive` field while an animation is playing.
    //
    func animateUIToMatchState() {
        let identifierVisibleString = identifierVisible == nil ? "" : identifierVisible
        let idenfifierActiveString = identifierActive == nil ? "" : identifierActive
        if identifierVisibleString == idenfifierActiveString {
            return
        }
        if isAnimating {
            return
        }
        isAnimating = true
        animationView.presentView(viewActive!, identifier: identifierActive!)
    }
    
    func animationViewDidFinishPresenting(identifier: String?) {
        isAnimating = false
        identifierVisible = identifier
        animateUIToMatchState()
    }
}