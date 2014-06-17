
#import "PHMainViewController.h"
#import "PHAnimationView.h"
#import "UIColor+PHColor.h"
#import "PopHello-Swift.h"

@interface PHMainViewController ()
@end

@implementation PHMainViewController {
    PHAnimationView *_animationView;
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
    
    _animationView = [[PHAnimationView alloc] init];
    _animationView.delegate = self;
    [self.view addSubview:_animationView];
    
    _animationView.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *view = self.view;
    NSDictionary *bindings = NSDictionaryOfVariableBindings(view, _animationView);
    NSArray *fmts = @[@"V:|[_animationView]|", @"|[_animationView]|"];
    for (NSString *fmt in fmts) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt
                                                                     options:0
                                                                     metrics:nil
                                                                       views:bindings]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShowOrWillHide:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShowOrWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

// Handle the keyboard appearing or disappearing.
//
// Resize the content so that it isn't obscured by the keyboard if it appears.
//
- (void)keyboardDidShowOrWillHide:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrameEnd = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, keyboardFrameEnd.origin.y);
    [self.view layoutIfNeeded];
}

- (void)presentTagView:(Tag *)card
                server:(Server *)server
              delegate:(id<TagViewDelegate>)delegate
{
    _identifierActive = [NSString stringWithFormat:@"tag-%@", card.id];
    _viewActive = [[TagView alloc] initWithCard:card server:server delegate:delegate];
    [self animateUIToMatchState];
}

- (void)presentTagCreate:(ZoneManager *)zoneManager
                  server:(Server *)server
                delegate:(id<TagCreateViewDelegate>)delegate
{
    _identifierActive = @"tag-creation";
    _viewActive = [[TagCreateView alloc] initWithZoneManager:zoneManager server:server delegate:delegate];
    [self animateUIToMatchState];
}

- (void)presentTagCreationSuccess
{
    _identifierActive = @"tag-creation-success";
    _viewActive = [[TagCreateSuccessView alloc] init];
    [self animateUIToMatchState];
}

- (void)presentServerError
{
    _identifierActive = @"server-error";
    _viewActive = [[ServerErrorView alloc] init];
    [self animateUIToMatchState];
}

- (void)presentPending
{
    _identifierActive = @"pending";
    _viewActive = [[PendingView alloc] init];
    [self animateUIToMatchState];
}

- (void)presentServiceUnavailable:(NSString *)reason
{
    _identifierActive = @"service-unavailable";
    _viewActive = [[ServiceUnavailableView alloc] initWithReason:reason];
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
