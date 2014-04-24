
#import "PHUserView.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"
#import "UIImage+PHImage.h"

@implementation PHUserView

- (id)initWithName:(NSString *)name imageURL:(NSString *)imageURL
{
    self = [super initWithFrame:CGRectNull];
    if (self) {
        
        static CGFloat const userImageSize = 50;
        NSURL *url = [NSURL URLWithString:imageURL];
        UIImage *imagePlaceholder = [UIImage imageWithColor:[UIColor ph_userImagePlaceholderColor] size:userImageSize];
        UIImageView *avatar = [[UIImageView alloc] initWithImage:imagePlaceholder];
        avatar.layer.cornerRadius = userImageSize / 2;
        avatar.layer.masksToBounds = YES;
        [self addSubview:avatar];
        
        UILabel *labelName = [[UILabel alloc] init];
        labelName.text = name;
        labelName.font = [UIFont ph_usernameFont];
        labelName.textColor = [UIColor ph_usernameTextColor];
        labelName.textAlignment = NSTextAlignmentCenter;
        [self addSubview:labelName];
        
        avatar.translatesAutoresizingMaskIntoConstraints = NO;
        labelName.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(self, avatar, labelName);
        NSArray *fmts = @[[NSString stringWithFormat:@"V:|[avatar(%f)]-10-[labelName]|", userImageSize],
                          [NSString stringWithFormat:@"|-(>=0)-[avatar(%f)]-(>=0)-|", userImageSize],
                          @"|[labelName]|"];
        for (NSString *fmt in fmts) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt
                                                                         options:0
                                                                         metrics:nil
                                                                           views:bindings]];
        }
        // can't achieve center align with pure VFL
        [self addConstraint: [NSLayoutConstraint constraintWithItem:avatar
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0]];
        
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
