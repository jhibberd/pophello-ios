
#import <Foundation/Foundation.h>

@protocol PHAnimationViewDelegate <NSObject>
- (void)animationViewDidFinishPresenting:(NSString *)identifier;
@end
