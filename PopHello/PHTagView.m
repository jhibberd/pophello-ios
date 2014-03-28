
#import "PHTagView.h"

@implementation PHTagView

- (id)initWithFrame:(CGRect)frame tag:(NSDictionary *)tag
{
    self = [super initWithFrame:frame];
    if (self) {
    
        self.backgroundColor = [UIColor whiteColor];
        
        // init text label
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        textLabel.numberOfLines = 0;
        textLabel.text = tag[@"text"];
        [self addSubview:textLabel];
        
        // define layout
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(self, textLabel);
        NSArray *fmts = @[@"V:|-10-[textLabel]-(>=10)-|",
                          @"|-10-[textLabel]-10-|",
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
