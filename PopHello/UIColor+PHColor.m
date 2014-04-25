
#import "UIColor+PHColor.h"

@implementation UIColor (PHColor)

+ (UIColor *)ph_appBackgroundColor
{
    return [UIColor colorWithRed:233/255. green:234/255. blue:237/255. alpha:1];
}

+ (UIColor *)ph_contentBackgroundColor
{
    return [UIColor whiteColor];
}

+ (UIColor *)ph_successBackgroundColor
{
    return [UIColor colorWithRed:153/255. green:204/255. blue:0 alpha:1];
}

+ (UIColor *)ph_failureBackgroundColor
{
    return [UIColor colorWithRed:255/255. green:68/255. blue:68/255. alpha:1];
}

+ (UIColor *)ph_pendingTextColor
{
    return [UIColor colorWithRed:88/255. green:88/255. blue:88/255. alpha:1];
}

+ (UIColor *)ph_mainTextColor
{
    return [UIColor blackColor];
}

+ (UIColor *)ph_buttonTextColor
{
    return [UIColor colorWithRed:0 green:153/255. blue:204/255. alpha:1];
}

+ (UIColor *)ph_successTextColor
{
    return [UIColor whiteColor];
}

+ (UIColor *)ph_failureTextColor
{
    return [UIColor whiteColor];
}

+ (UIColor *)ph_userImagePlaceholderColor
{
    return [UIColor colorWithWhite:.95 alpha:1];
}

+ (UIColor *)ph_buttonBorderContentColor
{
    return [UIColor colorWithWhite:.95 alpha:1];
}

@end
