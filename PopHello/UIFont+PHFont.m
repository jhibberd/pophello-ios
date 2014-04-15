
#import "UIFont+PHFont.h"

static CGFloat const kPHPrimaryFontSize = 22;
static CGFloat const kPHSecondaryFontSize = 15;

@implementation UIFont (PHFont)

+ (UIFont *)ph_primaryFont
{
    return [UIFont systemFontOfSize:kPHPrimaryFontSize];
}

+ (UIFont *)ph_boldPrimaryFont
{
    return [UIFont boldSystemFontOfSize:kPHPrimaryFontSize];
}

+ (UIFont *)ph_usernameFont
{
    return [UIFont systemFontOfSize:kPHSecondaryFontSize];
}

@end
