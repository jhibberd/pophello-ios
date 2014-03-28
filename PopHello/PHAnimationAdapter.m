
#import "PHAnimationAdapter.h"

@implementation PHAnimationAdapter

- (id)initWithId:(NSString *)identifer data:(NSDictionary *)data
{
    self = [super init];
    if (self) {
        _identifier = identifer;
        _data = data;
    }
    return self;
}

- (UIView *)makeView:(CGRect)bounds
{
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithId:_identifier data:_data];
}

@end
