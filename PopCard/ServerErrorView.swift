import UIKit

// Indicate to the user that an error has occurred.
//
class ServerErrorView: UIView {

    init() {
        super.init(frame: CGRectNull) // auto layout
        
        backgroundColor = Palette.failureBackgroundColor
        
        let label = UILabel()
        label.font = Font.boldPrimaryFont
        label.textColor = Palette.failureTextColor
        label.numberOfLines = 0
        label.text = NSLocalizedString("SERVER_ERROR", comment: "")
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
