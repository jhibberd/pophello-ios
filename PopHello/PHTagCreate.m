
#import <CoreLocation/CoreLocation.h>
#import "PHTagCreate.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"

@implementation PHTagCreate {
    UITextView *_textView;
    UIButton *_button;
    PHZoneManager *_zoneManager;
    PHServer *_server;
    id<PHTagCreateDelegate> _delegate;
}

- (id)initWithFrame:(CGRect)frame
        zoneManager:(PHZoneManager *)zoneManager
             server:(PHServer *)server
           delegate:(id<PHTagCreateDelegate>)delegate
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor ph_contentBackgroundColor];
        
        _textView = [[UITextView alloc] init];
        _textView.font = [UIFont ph_primaryFont];
        _textView.backgroundColor = [UIColor ph_contentBackgroundColor];
        _textView.textColor = [UIColor ph_mainTextColor];
        _textView.textContainer.lineFragmentPadding = 10; // to match UILabel padding
        _textView.scrollEnabled = NO; // otherwise layout constraints don't work
        [_textView becomeFirstResponder];
        [self addSubview:_textView];
        
        _button = [[UIButton alloc] init];
        _button.backgroundColor = [UIColor ph_contentBackgroundColor];
        _button.titleLabel.font = [UIFont ph_primaryFont];
        [_button setTitleColor:[UIColor ph_buttonTextColor] forState:UIControlStateNormal];
        [_button setTitle:NSLocalizedString(@"TAG_CREATE_SUBMIT", nil) forState:UIControlStateNormal];
        [_button addTarget:self
                    action:@selector(buttonSubmitWasClicked)
          forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_button];
        
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(self, _textView, _button);
        NSArray *fmts = @[@"V:|[_textView]-(>=0)-[_button(55)]|",
                          @"|[_textView]|",
                          @"|[_button]|",
                          [NSString stringWithFormat:@"[self(%f)]", self.frame.size.width],     // fill width
                          [NSString stringWithFormat:@"V:[self(%f)]", self.frame.size.height]]; // fill height
        for (NSString *fmt in fmts) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt
                                                                         options:0
                                                                         metrics:nil
                                                                           views:bindings]];
        }
        
        _server = server;
        _zoneManager = zoneManager;
        _delegate = delegate;
    }
    return self;
}

// Handle the user submitting their tag for creation.
//
// If the location service hasn't been able to obtain the device location then don't attempt to submit the tag to the
// server and inform the user to try again shortly.
//
// If the submission can be made then disable the view to prevent the user from editing it while the request is sent to
// the server.
//
- (void)buttonSubmitWasClicked
{
    NSString *text = _textView.text;
    if (text.length == 0) {
        return;
    }
 
    CLLocationCoordinate2D location = [_zoneManager getLastPreciseLocation];
    if (!CLLocationCoordinate2DIsValid(location)) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"PopHello"
                                                        message:NSLocalizedString(@"LOCATION_UNKNOWN", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [_textView setEditable:NO];
    [_button setEnabled:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate newTagCreationWasSubmitted];
    });
    
    [_server postTagAt:location
                  text:text
        successHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate newTagCreationDidSucceed];
            });
        }
          errorHandler:^(NSDictionary *response) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  [_delegate newTagCreationDidFail];
              });
          }];
}

@end
