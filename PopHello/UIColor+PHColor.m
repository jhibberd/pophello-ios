
#import "UIColor+PHColor.h"

@implementation UIColor (PHColor)

+ (UIColor *)ph_unavailableColor
{
    return [UIColor colorWithRed:255/255. green:68/255. blue:68/255. alpha:1];
}

+ (UIColor *)ph_tagBackgroundColor
{
    return [UIColor colorWithRed:51/255. green:181/255. blue:229/255. alpha:1];
}

@end
