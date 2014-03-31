
#import "UIFont+PHFont.h"

static CGFloat const kXXPrimaryFontSize = 22;

@implementation UIFont (PHFont)

+ (UIFont *)ph_primaryFont
{
    return [UIFont systemFontOfSize:kXXPrimaryFontSize];
}

+ (UIFont *)ph_boldPrimaryFont
{
    return [UIFont boldSystemFontOfSize:kXXPrimaryFontSize];
}

@end
