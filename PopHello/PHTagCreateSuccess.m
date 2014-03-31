
#import "PHTagCreateSuccess.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"

@implementation PHTagCreateSuccess

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor ph_successBackgroundColor];
        
        // init text label
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.font = [UIFont ph_boldPrimaryFont];
        textLabel.backgroundColor = [UIColor ph_successBackgroundColor];
        textLabel.textColor = [UIColor ph_successTextColor];
        textLabel.numberOfLines = 0;
        textLabel.text = NSLocalizedString(@"TAG_CREATE_SUCCESS", nil);
        [self addSubview:textLabel];
        
        // define layout
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(self, textLabel);
        NSArray *fmts = @[@"V:|-15-[textLabel]-(>=15)-|",
                          @"|-15-[textLabel]-15-|",
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
