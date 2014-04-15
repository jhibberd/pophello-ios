
#import "PHUserView.h"
#import "UIColor+PHColor.h"
#import "UIFont+PHFont.h"
#import "UIImage+PHImage.h"

@implementation PHUserView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectNull];
    if (self) {
        
        static CGFloat const userImageSize = 50;
        
        NSString *URLString = @"https://fbcdn-profile-a.akamaihd.net/hprofile-ak-ash3/t1.0-1/c25.28.155.155/s50x50/946522_10151756173271454_1228308319_a.jpg";
        NSURL *url = [NSURL URLWithString:URLString];
        
        UIImage *imagePlaceholder = [UIImage imageWithColor:[UIColor ph_userImagePlaceholderColor] size:userImageSize];
        UIImageView *avatar = [[UIImageView alloc] initWithImage:imagePlaceholder];
        avatar.layer.cornerRadius = userImageSize / 2;
        avatar.layer.masksToBounds = YES;
        [self addSubview:avatar];
        
        UILabel *labelName = [[UILabel alloc] init];
        labelName.text = @"James Hibberd";
        labelName.font = [UIFont ph_usernameFont];
        labelName.textColor = [UIColor ph_usernameTextColor];
        labelName.textAlignment = NSTextAlignmentCenter;
        [self addSubview:labelName];
        
        avatar.translatesAutoresizingMaskIntoConstraints = NO;
        labelName.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(self, avatar, labelName);
        NSArray *fmts = @[[NSString stringWithFormat:@"V:|[avatar(%f)]-10-[labelName]|", userImageSize],
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
