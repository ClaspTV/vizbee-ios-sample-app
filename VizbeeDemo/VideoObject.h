//
//  Copyright © Vizbee Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VideoObject : NSObject

@property (nonatomic, copy) NSString* guid;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* subTitle;
@property (nonatomic, copy) NSString* genre;
@property (nonatomic, copy) NSString* shortDescription;
@property (nonatomic, copy) NSString* longDescription;
@property (nonatomic, copy) NSString* captionsURL;
@property (nonatomic, strong) NSURL* imageURL;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) NSURL* contentURL;
@property (nonatomic, strong) NSArray* adBreaks;
@property (nonatomic, assign) BOOL isLive;


-(id) initWithTitle:(NSString*)title
               guid:(NSString*)guid
     imageURLString:(NSString*)image
   contentURLString:(NSString*)content;

-(id) initWithDictionary:(NSDictionary*) dict;

@end
