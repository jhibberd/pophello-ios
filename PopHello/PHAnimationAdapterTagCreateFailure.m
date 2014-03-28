
#import "PHAnimationAdapterTagCreateFailure.h"
#import "PHTagCreateFailure.h"

// TODO: should the margin be specified here?
static CGFloat const kPHTagViewMarginLeftRight = 15;
static CGFloat const kPHTagViewMarginTop = 30;
static CGFloat const kPHTagViewHeight = 220;

@implementation PHAnimationAdapterTagCreateFailure

- (id)init
{
    return [super initWithId:@"tag-create-failure" data:nil];
}

- (UIView *)makeView:(CGRect)bounds
{
    // TODO: make slightly higher to accomodate the button height
    CGRect frame = CGRectMake(bounds.origin.x + kPHTagViewMarginLeftRight,
                              bounds.origin.y + kPHTagViewMarginTop,
                              bounds.size.width - (kPHTagViewMarginLeftRight *2),
                              kPHTagViewHeight);
    return [[PHTagCreateFailure alloc] initWithFrame:frame];
}

@end
