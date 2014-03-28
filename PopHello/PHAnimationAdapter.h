
#import <Foundation/Foundation.h>

@interface PHAnimationAdapter : NSObject <NSCopying> {
    NSDictionary *_data; // data used to generate the view
}
@property (nonatomic, readonly) NSString *identifier;
- (id)initWithId:(NSString *)identifer data:(NSDictionary *)data;
- (UIView *)makeView:(CGRect)bounds;
@end
