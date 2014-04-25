
#import "MWLogging.h"
#import "PHAnimationView.h"
#import "UIColor+PHColor.h"

static CFTimeInterval const kPHAnimationDuration = .5;
static NSString *const kPHAnimationKey = @"view-animation";

@implementation PHAnimationView {
    UIView *_viewVisible;
    NSString *_identifierVisible;
}

// Present a new UIView by animating it into view.
//
// A test showed that it's safe for the main view controller to point the view pointer to a different view while the
// animation is still playing.
//
- (void)presentView:(UIView *)view identifier:(NSString *)identifier
{
    if (_viewVisible != nil) {
        [_viewVisible removeFromSuperview];
    }
    [self addSubview:view];
    _viewVisible = view;
    _identifierVisible = identifier;
    
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *bindings = NSDictionaryOfVariableBindings(self, view);
    NSArray *fmts = @[@"V:|[view]|", @"|[view]|"];
    for (NSString *fmt in fmts) {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt
                                                                     options:0
                                                                     metrics:nil
                                                                       views:bindings]];
    }
    
    CATransition *animation = [CATransition animation];
	[animation setDuration:kPHAnimationDuration];
	[animation setType:kCATransitionPush];
	[animation setSubtype:kCATransitionFromRight];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    animation.delegate = self;
	[self.layer addAnimation:animation forKey:kPHAnimationKey];
}

// Notify the main view controller that the current animation has stopped and a new animation can begin.
//
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if (!flag) {
        MWLogWarning(@"Animation was interrupted");
    }
    [_delegate animationViewDidFinishPresenting:_identifierVisible];
}

// Clear the view.
//
// This isn't animated because when this occurs the app isn't visible to the user and it's important that it happens
// quickly.
//
- (void)presentNothingImmediately
{
    [self.layer removeAllAnimations];
    if (_viewVisible != nil) {
        [_viewVisible removeFromSuperview];
    }
    _viewVisible = nil;
    _identifierVisible = nil;
    [_delegate animationViewDidFinishPresenting:nil];
}

@end
