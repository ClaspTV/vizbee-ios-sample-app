//
//  Copyright © Vizbee Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoObject.h"

@interface VideoCatalog : NSObject

+(NSArray*) getCatalog;
+(VideoObject*) fetchVideoByUUID:(NSString*)uuidString ;

@end
