
#import "PHTagView.h"
#import "PHUserView.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"

@implementation PHTagView {
    NSString *_tagID;
    UIButton *_button;
    PHServer *_server;
    id<PHTagViewDelegate> _delegate;
}

- (id)initWithFrame:(CGRect)frame
                tag:(NSDictionary *)tag
             server:(PHServer *)server
           delegate:(id<PHTagViewDelegate>)delegate
{
    self = [super initWithFrame:frame];
    if (self) {
    
        self.backgroundColor = [UIColor ph_contentBackgroundColor];
        
        // init text label
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.font = [UIFont ph_primaryFont];
        textLabel.backgroundColor = [UIColor ph_contentBackgroundColor];
        textLabel.textColor = [UIColor ph_mainTextColor];
        textLabel.numberOfLines = 0;
        textLabel.text = tag[@"text"];
        [self addSubview:textLabel];
        
        PHUserView *userView = [[PHUserView alloc] initWithName:tag[@"user_id"] imageURL:tag[@"user_image_url"]];
        [self addSubview:userView];
        
        _button = [[UIButton alloc] init];
        _button.backgroundColor = [UIColor ph_contentBackgroundColor];
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
        NSArray *fmts = @[@"V:|-15-[textLabel]-(>=15)-[userView]-[_button(55)]|",
                          @"|-15-[textLabel]-15-|",
                          @"|-20-[userView]-20-|",
                          @"|[_button]|",
                          [NSString stringWithFormat:@"[self(%f)]", self.frame.size.width],     // fill width
                          [NSString stringWithFormat:@"V:[self(%f)]", self.frame.size.height]]; // fill height
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate tagAcknowledgementWasSubmitted];
    });
    
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
