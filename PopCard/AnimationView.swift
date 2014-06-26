import QuartzCore
import UIKit

protocol AnimationViewDelegate {
    func animationViewDidFinishPresenting(identifier: String?)
}

class AnimationView: UIView {
    
    let ANIMATION_DURATION = 0.5 // seconds
    let ANIMATION_KEY = "view-animation"
    
    var viewVisible: UIView?
    var identifierVisible: String?
    let delegate: AnimationViewDelegate?
    
    init(delegate: AnimationViewDelegate?) {
        super.init(frame: CGRectNull) // auto layout
        self.delegate = delegate
    }
    
    func presentView(view: UIView, identifier: String) {
        if let view = viewVisible {
            view.removeFromSuperview()
        }
        addSubview(view)
        identifierVisible = identifier
        
        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        let bindings = ["view": view]
        for fmt in ["V:|[view]|", "|[view]|"] {
            let constraints = NSLayoutConstraint.constraintsWithVisualFormat(
                fmt, options: .DirectionLeadingToTrailing, metrics: nil, views: bindings)
            addConstraints(constraints)
        }
        
        let animation = CATransition()
        animation.duration = ANIMATION_DURATION
        animation.type = kCATransitionPush
        animation.subtype = kCATransitionFromRight
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animation.delegate = self
        layer.addAnimation(animation, forKey: ANIMATION_KEY)
    }
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if !flag {
            println("Animation was interrupted")
        }
        delegate?.animationViewDidFinishPresenting(identifierVisible)
    }
    
    // Clear the view.
    //
    // This isn't animated because when this occurs the app isn't visible to the user and it's important that it 
    // happens quickly.
    //
    func presentNothingImmediately() {
        layer.removeAllAnimations()
        if let view = viewVisible {
            view.removeFromSuperview()
        }
        viewVisible = nil
        identifierVisible = nil
        delegate?.animationViewDidFinishPresenting(nil)
    }
}
