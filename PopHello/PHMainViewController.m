
#import "PHMainViewController.h"
#import "PHAnimationView.h"
#import "PHPending.h"
#import "PHServiceUnavailable.h"
#import "PHTagCreate.h"
#import "PHTagCreateFailure.h"
#import "PHTagCreateSuccess.h"
#import "PHTagView.h"
#import "UIColor+PHColor.h"

static CGFloat const kPHTopMargin = 30;
static CGFloat const kPHViewHeight = 295;

@interface PHMainViewController ()
@end

@implementation PHMainViewController {
    PHAnimationView *_animationView;
    CGRect _animationViewFrame;
    NSString *_identifierVisible;
    NSString *_identifierActive;
    UIView *_viewActive;
    BOOL _isAnimating;
}

// Initialise.
//
// All animations take place in a separate view to minimise the area of the screen involved in the animation and to
// provide additional padding between the slide in/out animations.
//
// The negative right margin in the autolayout constraints is the padding between views during animation.
//
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor ph_appBackgroundColor];
    
    _animationViewFrame = CGRectMake(0, 0, self.view.frame.size.width, kPHViewHeight);
    _animationView = [[PHAnimationView alloc] init];
    _animationView.delegate = self;
    [self.view addSubview:_animationView];
    
    _animationView.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *view = self.view;
    NSDictionary *bindings = NSDictionaryOfVariableBindings(view, _animationView);
    NSArray *fmts = @[[NSString stringWithFormat:@"V:|-%f-[_animationView(%f)]-(>=0)-|", kPHTopMargin, kPHViewHeight],
                      [NSString stringWithFormat:@"|[_animationView]-(-%f)-|", self.view.frame.size.width],
                      [NSString stringWithFormat:@"[view(%f)]", self.view.frame.size.width],     // fill width
                      [NSString stringWithFormat:@"V:[view(%f)]", self.view.frame.size.height]]; // fill height
    for (NSString *fmt in fmts) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt
                                                                     options:0
                                                                     metrics:nil
                                                                       views:bindings]];
    }    
}

- (void)presentTagView:(NSDictionary *)tag
{
    _identifierActive = [NSString stringWithFormat:@"tag-%@", tag[@"id"]];
    _viewActive = [[PHTagView alloc] initWithFrame:_animationViewFrame tag:tag];
    [self animateUIToMatchState];
}

- (void)presentTagCreate:(PHZoneManager *)zoneManager
                  server:(PHServer *)server
                delegate:(id<PHTagCreateDelegate>)delegate
{
    _identifierActive = @"tag-creation";
    _viewActive = [[PHTagCreate alloc] initWithFrame:_animationViewFrame
                                         zoneManager:zoneManager
                                              server:server
                                            delegate:delegate];
    [self animateUIToMatchState];
}

- (void)presentTagCreationSuccess
{
    _identifierActive = @"tag-creation-success";
    _viewActive = [[PHTagCreateSuccess alloc] initWithFrame:_animationViewFrame];
    [self animateUIToMatchState];
}

- (void)presentTagCreationFailure
{
    _identifierActive = @"tag-creation-failure";
    _viewActive = [[PHTagCreateFailure alloc] initWithFrame:_animationViewFrame];
    [self animateUIToMatchState];
}

- (void)presentPending
{
    _identifierActive = @"pending";
    _viewActive = [[PHPending alloc] initWithFrame:_animationViewFrame];
    [self animateUIToMatchState];
}

- (void)presentServiceUnavailable:(NSString *)reason
{
    _identifierActive = @"service-unavailable";
    _viewActive = [[PHServiceUnavailable alloc] initWithFrame:_animationViewFrame reason:reason];
    [self animateUIToMatchState];
}

- (void)presentNothing
{
    _identifierActive = nil;
    _viewActive = nil;
    [_animationView presentNothingImmediately];
}

// Animate the UI to match its active state (what it should be displaying).
//
// The identifier of the active state is compared with the identifier of the visible state. If both are equal then the
// UI is up to date and no further action needs to be taken. An identifier can be nil (displaying nothing), so these
// are converted to empty NSString objects to simplify comparison.
//
// If the UI is not up to date but an animation is currently in progress then return. When the current animation
// completes it will check to see whether the UI is up to date, find that it isn't and begin another animation to the
// active state.
//
// It's safe to modify the `_viewActive` field while an animation is playing.
//
- (void)animateUIToMatchState
{
    NSString *identifierVisibleString = _identifierVisible == nil ? @"" : _identifierVisible;
    NSString *idenfifierActiveString = _identifierActive == nil ? @"" : _identifierActive;
    if ([identifierVisibleString isEqualToString:idenfifierActiveString]) {
        return;
    }
    if (_isAnimating) {
        return;
    }
    _isAnimating = YES;
    [_animationView presentView:_viewActive identifier:_identifierActive];
}

- (void)animationViewDidFinishPresenting:(NSString *)identifier
{
    _isAnimating = NO;
    _identifierVisible = identifier;
    [self animateUIToMatchState];
}

@end
