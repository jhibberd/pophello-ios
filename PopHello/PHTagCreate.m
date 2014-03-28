
#import <CoreLocation/CoreLocation.h>
#import "PHTagCreate.h"

static float const kPHButtonHeight = 40;

@implementation PHTagCreate {
    UITextView *_textViewTag;
    UIButton *_buttonSubmit;
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
        
        self.backgroundColor = [UIColor whiteColor];
        
        // init text view
        _textViewTag = [[UITextView alloc] init];
        _textViewTag.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _textViewTag.textContainer.lineFragmentPadding = 10; // to match UILabel padding
        _textViewTag.scrollEnabled = NO; // otherwise layout constraints don't work
        [_textViewTag becomeFirstResponder];
        [self addSubview:_textViewTag];
        
        // init button
        _buttonSubmit = [[UIButton alloc] init];
        _buttonSubmit.backgroundColor = [UIColor greenColor];
        [_buttonSubmit setTitle:@"Post" forState:UIControlStateNormal];
        [_buttonSubmit addTarget:self
                          action:@selector(buttonSubmitWasClicked:)
                forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_buttonSubmit];
        
        // define layout
        _textViewTag.translatesAutoresizingMaskIntoConstraints = NO;
        _buttonSubmit.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(self, _textViewTag, _buttonSubmit);
        NSArray *fmts = @[@"V:|[_textViewTag][_buttonSubmit]|",
                          @"|[_textViewTag]|",
                          @"|[_buttonSubmit]|",
                          [NSString stringWithFormat:@"V:[_buttonSubmit(%f)]", kPHButtonHeight],
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
- (void)buttonSubmitWasClicked:(id)sender
{
    NSString *text = _textViewTag.text;
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
    
    [_textViewTag setEditable:NO];
    [_buttonSubmit setEnabled:NO];
    
    [_server postTagAt:location
                  text:text
        successHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate tagCreateDidSucceed];
            });
        }
          errorHandler:^(NSDictionary *response) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  [_delegate tagCreateDidFail];
              });
          }];
}

@end
