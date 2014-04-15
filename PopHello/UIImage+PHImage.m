
#import "UIImage+PHImage.h"

@implementation UIImage (PHImage)

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGFloat)size
{
    CGRect rect = CGRectMake(0, 0, size, size);
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
