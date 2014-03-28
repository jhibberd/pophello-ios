
#import "PHAnimationAdapterTagView.h"
#import "PHTagView.h"

// TODO: should the margin be specified here?
static CGFloat const kPHTagViewMarginLeftRight = 15;
static CGFloat const kPHTagViewMarginTop = 30;
static CGFloat const kPHTagViewHeight = 220;

@implementation PHAnimationAdapterTagView

- (id)initWithTag:(NSDictionary *)tag
{
    NSString *identifier = [NSString stringWithFormat:@"tag/%@", tag[@"id"]];
    return [super initWithId:identifier data:tag];
}

- (UIView *)makeView:(CGRect)bounds
{
    // TODO: make slightly higher to accomodate the button height
    CGRect frame = CGRectMake(bounds.origin.x + kPHTagViewMarginLeftRight,
                              bounds.origin.y + kPHTagViewMarginTop,
                              bounds.size.width - (kPHTagViewMarginLeftRight *2),
                              kPHTagViewHeight);
    return [[PHTagView alloc] initWithFrame:frame tag:_data];
}

@end
