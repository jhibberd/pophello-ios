import UIKit

// Indicate to the user that their tag was successfully created.
//
class TagCreateSuccessView: UIView {

    init() {
        super.init(frame: CGRectNull) // auto layout
        
        backgroundColor = Palette.successBackgroundColor
        
        let label = UILabel()
        label.font = Font.boldPrimaryFont
        label.backgroundColor = Palette.successBackgroundColor
        label.textColor = Palette.successTextColor
        label.numberOfLines = 0
        label.text = NSLocalizedString("TAG_CREATE_SUCCESS", comment: "")
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
