
#import "PHButton.h"
#import "PHTagView.h"
#import "PHUserView.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"


@implementation PHTagView {
    NSString *_tagID;
    PHButton *_button;
    PHServer *_server;
    id<PHTagViewDelegate> _delegate;
}

- (id)initWithTag:(NSDictionary *)tag server:(PHServer *)server delegate:(id<PHTagViewDelegate>)delegate
{
    self = [super init];
    if (self) {
    
        self.backgroundColor = [UIColor ph_contentBackgroundColor];
        
        PHUserView *userView = [[PHUserView alloc] initWithName:tag[@"user_id"] imageURL:tag[@"user_image_url"]];
        [self addSubview:userView];
        
        // init text label
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.font = [UIFont ph_primaryFont];
        textLabel.backgroundColor = [UIColor ph_contentBackgroundColor];
        textLabel.textColor = [UIColor ph_mainTextColor];
        textLabel.numberOfLines = 0;
        textLabel.text = tag[@"text"];
        [self addSubview:textLabel];
        
        _button = [[PHButton alloc] init];
        _button.titleLabel.font = [UIFont ph_primaryFont];
        [_button setTitleColor:[UIColor ph_buttonTextColor] forState:UIControlStateNormal];
        [_button setTitle:NSLocalizedString(@"TAG_ACKNOWLEDGE", nil) forState:UIControlStateNormal];
        [_button addTarget:self
                    action:@selector(buttonSubmitWasClicked)
          forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_button];
        
        // define layout
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        userView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(self, textLabel, _button, userView);
        NSArray *fmts = @[@"V:|-30-[userView]-50-[textLabel]-(>=15)-[_button(55)]|",
                          @"|-15-[textLabel]-15-|",
                          @"|-15-[userView]-15-|",
                          @"|[_button]|"];
        for (NSString *fmt in fmts) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt
                                                                         options:0
                                                                         metrics:nil
                                                                           views:bindings]];
        }
        
        _tagID = tag[@"id"];
        _server = server;
        _delegate = delegate;
    }
    return self;
}

// Handle the user submitting their tag acknowledgement.
//
- (void)buttonSubmitWasClicked
{
    [_button setEnabled:NO];
    [_delegate tagAcknowledgementWasSubmitted];
    
    [_server acknowledgeTag:_tagID
             successHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate tagAcknowledgementDidSucceed:_tagID];
            });
        }
               errorHandler:^(NSDictionary *response) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  [_delegate tagAcknowledgementDidFail];
              });
          }];
}

@end
