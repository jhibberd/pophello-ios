
#import <Foundation/Foundation.h>
#import "PHAnimationAdapter.h"
#import "PHServer.h"
#import "PHTagCreateDelegate.h"
#import "PHZoneManager.h"

@interface PHAnimationAdapterTagCreate : PHAnimationAdapter
- (id)initWithZoneManager:(PHZoneManager *)zoneManager
                   server:(PHServer *)server
                 delegate:(id<PHTagCreateDelegate>)delegate;
@end
