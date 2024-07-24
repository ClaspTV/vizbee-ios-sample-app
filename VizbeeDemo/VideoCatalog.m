//
//  Copyright © Vizbee Inc. All rights reserved.
//

#import "VideoCatalog.h"
#import "VideoObject.h"

@implementation VideoCatalog

+(NSArray*) getCatalog {
    
    static NSMutableArray* catalog = nil;
    if (catalog == nil) {catalog = [[NSMutableArray alloc] init];
        
        [catalog addObject:[[ VideoObject alloc] initWithDictionary:
                            @{ @"title":@"Sintel",
                               @"subTitle":@"Free MP4 video",
                               @"guid":@"sintel",
                               @"imageURLString":@"https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Sintel_poster.jpg/220px-Sintel_poster.jpg",
                               @"contentURLString":@"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
                               @"isLive":@NO,
                               @"captionsURL":@"https://bitdash-a.akamaihd.net/content/sintel/hls/subtitles_en.vtt",
                               @"longDescription": @"The film follows a girl named Sintel who is searching for a baby dragon she calls Scales. A flashback reveals that Sintel found Scales with its wing injured and helped care for it, forming a close bond with it. By the time its wing recovered and it was able to fly, Scales was caught by an adult dragon. Sintel has since embarked on a quest to rescue Scales, fending off beasts and warriors along the way. She eventually comes across a cave housing an adult and baby dragon, the latter of which she believes to be Scales. The adult dragon discovers and attacks Sintel, but hesitates to kill her. Sintel slays the dragon, only to recognize the scar on its wing and realize the dragon is an adult Scales, and that she too has aged considerably. Sintel leaves the cave heartbroken, unknowingly followed by Scales's baby."
                               }]];
        
        [catalog addObject:[[ VideoObject alloc] initWithDictionary:
                            @{ @"title":@"Big Buck Bunny",
                               @"subTitle":@"Free MP4 video",
                               @"guid":@"bigbuck",
                               @"imageURLString":@"https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Big_buck_bunny_poster_big.jpg/220px-Big_buck_bunny_poster_big.jpg",
                               // @"contentURLString":@"http://commondatastorage.googleapis.com/gtv-videos-bucket/big_buck_bunny_1080p.mp4",
                               @"contentURLString":@"https://playertest.longtailvideo.com/adaptive/bbbfull/bbbfull.m3u8",
                               @"isLive":@NO,
                               @"longDescription":@"A recently awoken enormous and utterly adorable fluffy rabbit is heartlessly harassed by a flying squirrel's gang of rodents who are determined to squash his happiness."
                               }]];
        
        [catalog addObject:[[ VideoObject alloc] initWithDictionary:
                            @{ @"title":@"Tears of Steel",
                               @"subTitle":@"Free HLS video",
                               @"guid":@"tears",
                               // @"imageURLString":@"https://s3.amazonaws.com/vizbee/images/demoapp/tearsofsteel.png",
                               @"imageURLString":@"https://upload.wikimedia.org/wikipedia/commons/thumb/7/70/Tos-poster.png/440px-Tos-poster.png",
                               @"contentURLString":@"https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/TearsOfSteel.m3u8",
                               @"isLive":@NO,
                               @"captionsURL":@"https://s3.amazonaws.com/vizbee/captions/TOS-en.vtt",
                               @"longDescription":@"Tears of Steel (code-named Project Mango) is a live-action/CGI short film by producer Ton Roosendaal and director/writer Ian Hubert. The film was made using new enhancements to the visual effects capabilities of Blender, a free and open source all-in-one 3D computer graphics software package."
                               }]];
        
        [catalog addObject:[[ VideoObject alloc] initWithDictionary:
                            @{ @"title":@"Elephants Dream",
                               @"subTitle":@"Free HLS video",
                               @"guid":@"elephants",
                               @"imageURLString":@"https://s3.amazonaws.com/vizbee/images/demoapp/elephantsdream.jpg",
                               @"contentURLString":@"https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/ElephantsDream.m3u8",
                               @"isLive":@NO,
                               @"longDescription":@"Emo and Proog are two men exploring a strange industrial world of the future."
                               }]];
        
    }
    return catalog;
}

+(VideoObject*) fetchVideoByUUID:(NSString*)uuidString {
    NSArray* my_catalog = [VideoCatalog getCatalog];
    for (VideoObject* video in my_catalog) {
        if( [video.guid isEqualToString:uuidString]) {
            return video;
        }
    }
    return nil;
}


@end
