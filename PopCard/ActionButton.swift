import UIKit

// Display a prominent button that performs the main user action on a view.
//
class ActionButton: UIButton {
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, Palette.buttonBorderContentColor.CGColor)
        CGContextFillRect(context, CGRectMake(0, 0, self.frame.size.width, 1))
    }
}