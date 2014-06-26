import UIKit

// Indicate to the user that the app is busy contacting the server.
//
class PendingView: UIView {

    init() {
        super.init(frame: CGRectNull) // auto layout
        
        backgroundColor = Palette.appBackgroundColor
        
        let label = UILabel()
        label.font = Font.primaryFont
        label.backgroundColor = Palette.appBackgroundColor
        label.textColor = Palette.pendingTextColor
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
