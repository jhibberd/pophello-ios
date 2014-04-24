
#import <UIKit/UIKit.h>
#import "PHServer.h"
#import "PHTagViewDelegate.h"

@interface PHTagView : UIView
- (id)initWithFrame:(CGRect)frame tag:(NSDictionary *)tag
             server:(PHServer *)server
           delegate:(id<PHTagViewDelegate>)delegate;
@end
