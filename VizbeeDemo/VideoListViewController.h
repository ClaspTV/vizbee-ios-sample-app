//
//  Copyright © Vizbee Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoObject.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VideoListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSTimer *timer;
}

@property (weak, nonatomic) IBOutlet UITableView *videoListTableView;
@property (nonatomic, assign) int counter;

- (void)updateNowPlayingInfo;
- (void)setupRemoteCommandCenter;
- (void)play;
- (void)pause;
- (void)nextTrack;
- (void)previousTrack;
- (void)updatePlaybackInfo;
- (void)startUpdatingPlaybackInfo;

@end

