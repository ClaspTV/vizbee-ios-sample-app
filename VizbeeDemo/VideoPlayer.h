//
//  Copyright © Vizbee Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VideoObject.h"


@interface VideoPlayer : NSObject

+(void) playVideo:(VideoObject*) video
       atPosition:(NSTimeInterval)playHeadTime
presentingViewController:(UIViewController *)viewController;

+(void) playVideo:(VideoObject*) video
       atPosition:(NSTimeInterval)playHeadTime
   shouldAutoPlay:(BOOL)shouldAutoPlay
presentingViewController:(UIViewController *)viewController;

@end
