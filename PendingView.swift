import UIKit

// Indicate to the user that the app is busy contacting the server.
//
class PendingView: UIView {

    init() {
        super.init(frame: CGRectNull) // auto layout
        
        backgroundColor = UIColor.ph_appBackgroundColor()
        
        let label = UILabel()
        label.font = UIFont.ph_primaryFont()
        label.backgroundColor = UIColor.ph_appBackgroundColor()
        label.textColor = UIColor.ph_pendingTextColor()
        label.numberOfLines = 0
        label.text = NSLocalizedString("PENDING", comment: "")
        addSubview(label)
        
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        let bindings = ["self": self, "label": label]
        for fmt in ["V:|-30-[label]-(>=15)-|", "|-15-[label]-15-|"] {
            let constraints = NSLayoutConstraint.constraintsWithVisualFormat(
                fmt, options: .DirectionLeadingToTrailing, metrics: nil, views: bindings)
            addConstraints(constraints)
        }
    }
}
