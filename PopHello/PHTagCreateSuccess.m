
#import "PHTagCreateSuccess.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"

@implementation PHTagCreateSuccess

- (id)init
{
    self = [super init];
    if (self) {
        
        self.backgroundColor = [UIColor ph_successBackgroundColor];
        
        // init text label
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.font = [UIFont ph_boldPrimaryFont];
        textLabel.textColor = [UIColor ph_successTextColor];
        textLabel.numberOfLines = 0;
        textLabel.text = NSLocalizedString(@"TAG_CREATE_SUCCESS", nil);
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
