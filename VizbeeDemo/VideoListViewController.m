//
//  Copyright © Vizbee Inc. All rights reserved.
//

#import "VideoListViewController.h"
#import "VideoCatalog.h"
#import "VideoPlayer.h"
#import <VizbeeKit/VizbeeKit.h>
#import "SettingsViewController.h"
#import "VideoDetailsViewController.h"

@interface VideoListViewController ()

@end

@implementation VideoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self createAndAddSettingsButton];
    [self.navigationItem setTitle:@"Vizbee Demo App"];
    [self.videoListTableView setDataSource:self];
    [self.videoListTableView setDelegate:self];
    
    //------------------------------
    // [Begin] Vizbee Integration Code
    //------------------------------
    
    // Use this API to add cast icon to all of your app's view controllers.
    
    [Vizbee addCastIconToNavigationItem:self.navigationItem withViewController:self];
    
    //------------------------------
    // [End] Vizbee Integration Code
    //------------------------------
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //------------------------------
    // [Begin] Vizbee Integration Code
    //------------------------------
    
    // NOTES:
    // Beyond, casting Vizbee provides a number of conversion flows to combine the
    // best features of our mobile devices with the great viewing experience of
    // big screen TVs.
    //
    // Vizbee's "SmartHelp" API will allow the invocation of Smart Install and Cast Introduction
    // 1. Cast Introduction flow intuitively introduce your users to the available devices on their network that they can cast to.
    // 2. Smart Install flow helps in driving automatic installation of your app on all household devices.
    
    [Vizbee smartHelp:self];
    
    //------------------------------
    // [End] Vizbee Integration Code
    //------------------------------
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL)shouldAutorotate {
    return NO;
}

//---------------
#pragma mark - Table view data source
//---------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0) ? [[VideoCatalog getCatalog] count] : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoObject * video = [[VideoCatalog getCatalog] objectAtIndex:[indexPath indexAtPosition:1]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"VideoCell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [cell setLayoutMargins:UIEdgeInsetsMake(8,0,8,0)];
    
    cell.textLabel.text = video.title;
    cell.detailTextLabel.text = video.subTitle;
    if (video.image != nil ) {
        cell.imageView.image = video.image;
        
        CGSize itemSize = CGSizeMake(80, 140);
        UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
        [cell.imageView.image drawInRect:imageRect];
        cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
    } else if (video.imageURL != nil) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:video.imageURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                video.image = [UIImage imageWithData:imageData];
                UITableViewCell *updateCell = (id)[tableView cellForRowAtIndexPath:indexPath];
                if (updateCell) {
                    updateCell.imageView.image = video.image;
                    updateCell.imageView.contentMode = UIViewContentModeScaleAspectFit;
                    
                    CGSize itemSize = CGSizeMake(80, 140);
                    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
                    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                    [cell.imageView.image drawInRect:imageRect];
                    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    [updateCell setNeedsLayout];
                }
            });
        });
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 148;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    VideoObject * video = [[VideoCatalog getCatalog] objectAtIndex:[indexPath indexAtPosition:1]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self presentVideoDetailsVCWithMovie:video];
}

-(void) createAndAddSettingsButton {
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc]
                                       initWithTitle:nil
                                       style:UIBarButtonItemStylePlain
                                       target:self
                                       action:@selector(presentSettingsVC)];
    [settingsButton setImage:[UIImage imageNamed:@"Settings-Image"]];
//    settingsButton.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = settingsButton;
}

-(void) presentSettingsVC {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SettingsViewControllerStoryboard" bundle:nil];
    SettingsViewController *settingsVC = [storyboard instantiateViewControllerWithIdentifier:@"SettingsViewControllerStoryboard"];
    [self.navigationController pushViewController:settingsVC animated:YES];
}

- (void)presentVideoDetailsVCWithMovie:(VideoObject *)movie {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"VideoDetailsViewController" bundle:nil];
    VideoDetailsViewController *videoDetailsController = [storyboard instantiateViewControllerWithIdentifier:@"VideoDetailsViewController"];
    videoDetailsController.movie = movie;
    [self.navigationController pushViewController:videoDetailsController animated:YES];
}

@end
