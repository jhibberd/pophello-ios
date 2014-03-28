
#import "PHAnimationAdapterTagCreate.h"
#import "PHTagCreate.h"

// TODO: should the margin be specified here?
static CGFloat const kPHTagViewMarginLeftRight = 15;
static CGFloat const kPHTagViewMarginTop = 30;
static CGFloat const kPHTagViewHeight = 220;

@implementation PHAnimationAdapterTagCreate {
    PHZoneManager *_zoneManager;
    PHServer *_server;
    id<PHTagCreateDelegate> _delegate;
}

- (id)initWithZoneManager:(PHZoneManager *)zoneManager
                   server:(PHServer *)server
                 delegate:(id<PHTagCreateDelegate>)delegate
{
    self = [super initWithId:@"create" data:nil];
    if (self) {
        _zoneManager = zoneManager;
        _server = server;
        _delegate = delegate;
    }
    return self;
}

- (UIView *)makeView:(CGRect)bounds
{
    // TODO: make slightly higher to accomodate the button height
    CGRect frame = CGRectMake(bounds.origin.x + kPHTagViewMarginLeftRight,
                              bounds.origin.y + kPHTagViewMarginTop,
                              bounds.size.width - (kPHTagViewMarginLeftRight *2),
                              kPHTagViewHeight);
    return [[PHTagCreate alloc] initWithFrame:frame zoneManager:_zoneManager server:_server delegate:_delegate];
}

@end
