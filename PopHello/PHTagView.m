
#import "PHTagView.h"
#import "PHUserView.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"

@implementation PHTagView

- (id)initWithFrame:(CGRect)frame tag:(NSDictionary *)tag
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
        
        PHUserView *userView = [[PHUserView alloc] init];
        [self addSubview:userView];
        
        UIButton *button = [[UIButton alloc] init];
        button.backgroundColor = [UIColor ph_contentBackgroundColor];
        button.titleLabel.font = [UIFont ph_primaryFont];
        [button setTitleColor:[UIColor ph_buttonTextColor] forState:UIControlStateNormal];
        [button setTitle:NSLocalizedString(@"TAG_VIEW_OK", nil) forState:UIControlStateNormal];
        [self addSubview:button];
        
        // define layout
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        userView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(self, textLabel, button, userView);
        NSArray *fmts = @[@"V:|-15-[textLabel]-(>=15)-[userView]-[button(55)]|",
                          @"|-15-[textLabel]-15-|",
                          @"|-20-[userView]-20-|",
                          @"|[button]|",
                          [NSString stringWithFormat:@"[self(%f)]", self.frame.size.width],     // fill width
                          [NSString stringWithFormat:@"V:[self(%f)]", self.frame.size.height]]; // fill height
        for (NSString *fmt in fmts) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt
                                                                         options:0
                                                                         metrics:nil
                                                                           views:bindings]];
        }
    }
    return self;
}

@end
