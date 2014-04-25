
#import "PHServiceUnavailable.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"

@implementation PHServiceUnavailable

- (id)initWithReason:(NSString *)reason
{
    self = [super init];
    if (self) {
        
        self.backgroundColor = [UIColor ph_failureBackgroundColor];
        
        // init text label
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.font = [UIFont ph_boldPrimaryFont];
        textLabel.backgroundColor = [UIColor ph_failureBackgroundColor];
        textLabel.textColor = [UIColor ph_failureTextColor];
        textLabel.numberOfLines = 0;
        textLabel.text = reason;
        [self addSubview:textLabel];
        
        // define layout
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(self, textLabel);
        NSArray *fmts = @[@"V:|-30-[textLabel]-(>=15)-|",
                          @"|-15-[textLabel]-15-|"];
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
