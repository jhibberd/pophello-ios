
#import "UIImage+PHImage.h"

@implementation UIImage (PHImage)

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGFloat)size
{
    CGRect rect = CGRectMake(0, 0, size, size);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
