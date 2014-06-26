import UIKit

// Indicate to the user that the service is unavailable.
//
class ServiceUnavailableView: UIView {
    
    init(reason: String) {
        super.init(frame: CGRectNull) // auto layout
        
        backgroundColor = Palette.failureBackgroundColor
        
        let label = UILabel()
        label.font = Font.boldPrimaryFont
        label.backgroundColor = Palette.failureBackgroundColor
        label.textColor = Palette.failureTextColor
        label.numberOfLines = 0
        label.text = reason
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
