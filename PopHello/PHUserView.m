
#import "PHUserView.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"
#import "UIImage+PHImage.h"

@implementation PHUserView

- (id)initWithName:(NSString *)name imageURL:(NSString *)imageURL
{
    self = [super initWithFrame:CGRectNull];
    if (self) {
        
        static CGFloat const userImageSize = 60;
        NSURL *url = [NSURL URLWithString:imageURL];
        UIImage *imagePlaceholder = [UIImage imageWithColor:[UIColor ph_userImagePlaceholderColor] size:userImageSize];
        UIImageView *avatar = [[UIImageView alloc] initWithImage:imagePlaceholder];
        [self addSubview:avatar];
        
        UILabel *labelName = [[UILabel alloc] init];
        labelName.text = name;
        labelName.font = [UIFont ph_usernameFont];
        labelName.textColor = [UIColor ph_mainTextColor];
        [self addSubview:labelName];
        
        avatar.translatesAutoresizingMaskIntoConstraints = NO;
        labelName.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(self, avatar, labelName);
        NSArray *fmts = @[[NSString stringWithFormat:@"V:|[avatar(%f)]-5-[labelName]|", userImageSize],
                          [NSString stringWithFormat:@"|[avatar(%f)]-(>=0)-|", userImageSize],
                          @"|[labelName]|"];
        for (NSString *fmt in fmts) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt
                                                                         options:0
                                                                         metrics:nil
                                                                           views:bindings]];
        }
        
        // async load the profile image from Facebook
        dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        dispatch_async(q, ^{
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *img = [[UIImage alloc] initWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                avatar.image = img;
            });
        });

    }
    return self;
}

@end
