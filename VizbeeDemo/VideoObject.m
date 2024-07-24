//
//  Copyright © Vizbee Inc. All rights reserved.
//

#import "VideoObject.h"

@implementation VideoObject

-(id) initWithTitle:(NSString*)title
               guid:(NSString*)guid
     imageURLString:(NSString*)image
   contentURLString:(NSString*)content {
    
    NSDictionary* d = @{ @"title":title, @"guid":guid, @"imageURLString":image, @"contentURLString":content};
    self = [self initWithDictionary:d];
    return self;
}


-(id) initWithDictionary:(NSDictionary*) dict {
    self = [super init];
    if (self != nil ) {
        
        for (NSString* key in dict) {
            if ([key isEqualToString:@"title"]) {
                self.title = [dict valueForKey:key];
            } else if ([key isEqualToString:@"subTitle"]) {
                self.subTitle = [dict valueForKey:key];
            } else if ([key isEqualToString:@"guid"]) {
                self.guid = [dict valueForKey:key];
            } else if ([key isEqualToString:@"genre"]) {
                self.genre = [dict valueForKey:key];
            } else if ([key isEqualToString:@"shortDescription"]) {
                self.genre = [dict valueForKey:key];
            } else if ([key isEqualToString:@"longDescription"]) {
                self.longDescription = [dict valueForKey:key];
            } else if ([key isEqualToString:@"imageURLString"]) {
                self.imageURL = [[NSURL alloc] initWithString:[dict valueForKey:key]];
            } else if ([key isEqualToString:@"contentURLString"]) {
                self.contentURL = [[NSURL alloc] initWithString:[dict valueForKey:key]];
            } else if ([key isEqualToString:@"isLive"]) {
                self.isLive = [[dict valueForKey:@"isLive"] boolValue];
            } else if ([key isEqualToString:@"cuePoints"]) {
                self.adBreaks =[ dict valueForKey:@"cuePoints"];
            } else if ([key isEqualToString:@"captionsURL"]) {
                self.captionsURL =[ dict valueForKey:@"captionsURL"];
            }
        }
    }
    return self;
}

@end

