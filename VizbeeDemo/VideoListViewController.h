//
//  Copyright © Vizbee Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoObject.h"

@interface VideoListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *videoListTableView;

@end

