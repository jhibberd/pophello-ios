
#import "PHMainViewController.h"
#import "PHAnimationAdapter.h"
#import "PHAnimationAdapterTagCreate.h"
#import "PHAnimationAdapterNothing.h"
#import "PHAnimationAdapterTagView.h"
#import "PHAnimationAdapterTagCreateSuccess.h"
#import "PHAnimationAdapterTagCreateFailure.h"
#import "UIColor+PHColor.h"

static NSTimeInterval const kPHAnimationDuration = 1;

@interface PHMainViewController ()
@end

@implementation PHMainViewController {
    PHAnimationAdapter* _viewDataVisible;
    PHAnimationAdapter* _viewDataActive;
    UIView *_viewVisible;
    BOOL _isAnimating;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor ph_tagBackgroundColor];
    
    // initial valid state showing nothing
    _viewDataActive = [[PHAnimationAdapterNothing alloc] init];
    _viewDataVisible = _viewDataActive;
    _viewVisible = [_viewDataActive makeView:CGRectNull];
}

- (void)presentTagView:(NSDictionary *)tag
{
    _viewDataActive = [[PHAnimationAdapterTagView alloc] initWithTag:tag];
    [self animateUIToMatchState];
}

- (void)presentTagCreate:(PHZoneManager *)zoneManager
                  server:(PHServer *)server
                delegate:(id<PHTagCreateDelegate>)delegate
{
    _viewDataActive = [[PHAnimationAdapterTagCreate alloc] initWithZoneManager:zoneManager
                                                                          server:server
                                                                        delegate:delegate];
    [self animateUIToMatchState];
}

- (void)presentTagCreateSuccess
{
    _viewDataActive = [[PHAnimationAdapterTagCreateSuccess alloc] init];
    [self animateUIToMatchState];
}

- (void)presentTagCreateFailure
{
    _viewDataActive = [[PHAnimationAdapterTagCreateFailure alloc] init];
    [self animateUIToMatchState];
}

// Show no view.
//
// This isn't animated because when this occurs the app isn't visible to the user and it's important that it happens
// quickly.
//
- (void)presentNothing
{
    [self.view.layer removeAllAnimations];
    if (_viewVisible != nil) {
        [_viewVisible removeFromSuperview];
    }
    _viewDataActive = [[PHAnimationAdapterNothing alloc] init];
    _viewDataVisible = _viewDataActive;
    _viewVisible = [_viewDataActive makeView:CGRectNull];
}

- (void)animateUIToMatchState
{
    // if the UI and state are already in sync take no further action
    if ([_viewDataVisible.identifier isEqualToString:_viewDataActive.identifier]) {
        return;
    }
    
    // if we're already animating then take no further action; when the current animation completes it will check
    // whether the UI matches the state and reanimate if not
    if (_isAnimating) {
        return;
    }
    _isAnimating = YES;
    
    // `_viewDataActive` can potentially be changed during the course of the animation. We don't want the object being
    // animated to change part way through the animation so make a local copy.
    PHAnimationAdapter *viewDataAnimating = [_viewDataActive copy];
    UIView *viewAfter = [_viewDataActive makeView:self.view.bounds];
    UIView *viewBefore = _viewVisible;
    
    // 1) nil -> view | fade in
    if (viewBefore == nil && viewAfter != nil) {
        viewAfter.alpha = 0;
        [self.view addSubview:viewAfter];
        [UIView animateWithDuration:kPHAnimationDuration animations:^{
            viewAfter.alpha = 1;
        } completion:^(BOOL finished) {
            _viewVisible = viewAfter;
            _viewDataVisible = viewDataAnimating;
            _isAnimating = NO;
            [self animateUIToMatchState];
        }];
        
    // 2) view -> nil | fade out
    } else if (viewBefore != nil && viewAfter == nil) {
        [UIView animateWithDuration:kPHAnimationDuration animations:^{
            viewBefore.alpha = 0;
        } completion:^(BOOL finished) {
            [viewBefore removeFromSuperview];
            _viewVisible = viewAfter;
            _viewDataVisible = viewDataAnimating;
            _isAnimating = NO;
            [self animateUIToMatchState];
        }];
        
    // 3) view -> view | transition from view to view
    } else {
        viewAfter.alpha = 0;
        [self.view addSubview:viewAfter];
        [UIView animateWithDuration:kPHAnimationDuration animations:^{
            viewBefore.alpha = 0;
        } completion:^(BOOL finished) {
            [viewBefore removeFromSuperview];
            [UIView animateWithDuration:kPHAnimationDuration animations:^{
                viewAfter.alpha = 1;
            } completion:^(BOOL finished) {
                _viewVisible = viewAfter;
                _viewDataVisible = viewDataAnimating;
                _isAnimating = NO;
                [self animateUIToMatchState];
            }];
        }];
    }
}

@end
