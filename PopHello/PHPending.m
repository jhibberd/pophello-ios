
#import "PHPending.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"

@implementation PHPending

- (id)init
{
    self = [super init];
    if (self) {
        
        self.backgroundColor = [UIColor ph_appBackgroundColor];
        
        // init text label
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.font = [UIFont ph_primaryFont];
        textLabel.textColor = [UIColor ph_pendingTextColor];
        textLabel.numberOfLines = 0;
        textLabel.text = NSLocalizedString(@"PENDING", nil);
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
