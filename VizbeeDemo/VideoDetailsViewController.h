//
//  VideoDetailsViewController.h
//  VizbeeDemo
//
//  Created by Work on 5/23/19.
//  Copyright © 2019 Prashanth Pappu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoDetailsViewController : UIViewController

@property (weak, nonatomic) VideoObject *movie;

@end

NS_ASSUME_NONNULL_END
