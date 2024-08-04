//
//  Copyright © Vizbee Inc. All rights reserved.
//

#import "VideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>


static AVPlayer *player;
NSTimer *timer;
int counter;

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
    player = [AVPlayer playerWithURL:videoURL];
    
    // create a player view controller
    AVPlayerViewController *controller = [[AVPlayerViewController alloc]init];
    controller.allowsPictureInPicturePlayback = false;
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
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    
//    // Register for the app entering background notification
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(handleDidEnterBackground)
//                                                     name:UIApplicationDidEnterBackgroundNotification
//                                                   object:nil];
//    
//    __weak typeof(self) weakSelf = self;
//    timer = [NSTimer scheduledTimerWithTimeInterval:1.0
//                                             repeats:YES
//                                               block:^(NSTimer * _Nonnull timer) {
//        __strong typeof(weakSelf) strongSelf = weakSelf;
//        if (strongSelf) {
//            counter++;
//            if (counter == 10) {
//                NSLog(@"VideoPlayer:: - Updating playbackinfo %ld, stopping player", (long)counter);
//                [self handleDidEnterBackground];
//            }
//        }
//    }];
}

// Method to handle the app entering background
//+(void) handleDidEnterBackground {
//    [player pause];
//    player = nil;
//}

@end
