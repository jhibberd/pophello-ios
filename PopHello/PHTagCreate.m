
#import <CoreLocation/CoreLocation.h>
#import "PHButton.h"
#import "PHTagCreate.h"
#import "PHUserView.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"


@implementation PHTagCreate {
    UITextView *_textView;
    PHButton *_button;
    PHZoneManager *_zoneManager;
    PHServer *_server;
    id<PHTagCreateDelegate> _delegate;
}

- (id)initWithZoneManager:(PHZoneManager *)zoneManager
             server:(PHServer *)server
           delegate:(id<PHTagCreateDelegate>)delegate
{
    self = [super init];
    if (self) {
        
        self.backgroundColor = [UIColor ph_contentBackgroundColor];
        
        PHUserView *userView = [[PHUserView alloc] initWithName:[self getUserID] imageURL:[self getUserImageURL]];
        [self addSubview:userView];
        
        _textView = [[UITextView alloc] init];
        _textView.font = [UIFont ph_primaryFont];
        _textView.backgroundColor = [UIColor ph_contentBackgroundColor];
        _textView.textColor = [UIColor ph_mainTextColor];
        _textView.textContainer.lineFragmentPadding = 15; // to match UILabel padding
        _textView.scrollEnabled = NO; // otherwise layout constraints don't work
        [_textView becomeFirstResponder];
        [self addSubview:_textView];
        
        _button = [[PHButton alloc] init];
        _button.titleLabel.font = [UIFont ph_primaryFont];
        [_button setTitleColor:[UIColor ph_buttonTextColor] forState:UIControlStateNormal];
        [_button setTitle:NSLocalizedString(@"TAG_CREATE_SUBMIT", nil) forState:UIControlStateNormal];
        [_button addTarget:self
                    action:@selector(buttonSubmitWasClicked)
          forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_button];
        
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        userView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(self, _textView, _button, userView);
        NSArray *fmts = @[@"V:|-30-[userView]-50-[_textView]-(>=15)-[_button(55)]|",
                          @"|[_textView]|",
                          @"|-15-[userView]-15-|",
                          @"|[_button]|"];
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
    [_delegate tagCreationWasSubmitted];
    
    [_server postTagAt:location
                  text:text
        successHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate tagCreationDidSucceed];
            });
        }
          errorHandler:^(NSDictionary *response) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  [_delegate tagCreationDidFail];
              });
          }];
}

- (NSString *)getUserID
{
    NSBundle *bundle = [NSBundle mainBundle];
    return [bundle objectForInfoDictionaryKey:@"UserID"];
}

- (NSString *)getUserImageURL
{
    NSBundle *bundle = [NSBundle mainBundle];
    return [bundle objectForInfoDictionaryKey:@"UserImageURL"];
}

@end
