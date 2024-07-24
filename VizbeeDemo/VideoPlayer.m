//
//  Copyright © Vizbee Inc. All rights reserved.
//

#import "VideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@implementation VideoPlayer

+(void) playVideo:(VideoObject*) video
       atPosition:(NSTimeInterval)playHeadTime
presentingViewController:(UIViewController *)viewController {
    
    [VideoPlayer playVideo:video
                atPosition:playHeadTime
            shouldAutoPlay:YES
  presentingViewController:viewController];
}

+(void) playVideo:(VideoObject*) video
       atPosition:(NSTimeInterval)playHeadTime
   shouldAutoPlay:(BOOL)shouldAutoPlay
presentingViewController:(UIViewController *)viewController {
    
    NSURL *videoURL = video.contentURL;
    
    // create an AVPlayer
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    
    // create a player view controller
    AVPlayerViewController *controller = [[AVPlayerViewController alloc]init];
    controller.player = player;
    
    [player seekToTime:CMTimeMake(playHeadTime,1)];
    if (shouldAutoPlay) {
        [player play];
    }
    
    // show the view controller
    [viewController presentViewController:controller animated:YES
                               completion:^{
                                   // handle completion as needed
                               }];
}

@end
