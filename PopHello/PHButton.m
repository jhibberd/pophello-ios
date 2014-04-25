
#import "PHButton.h"
#import "UIColor+PHColor.h"

// UIButton with top border.
//
@implementation PHButton

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor ph_buttonBorderContentColor].CGColor);
    CGContextFillRect(context, CGRectMake(0.0f, 0.0, self.frame.size.width, 1.0));
}


@end
