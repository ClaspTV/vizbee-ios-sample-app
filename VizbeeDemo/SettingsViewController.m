//
//  SettingsViewController.m
//  VizbeeDemo
//
//  Created by Work on 4/10/19.
//  Copyright © 2019 Prashanth Pappu. All rights reserved.
//

#import "SettingsViewController.h"

#import <VizbeeKit/VizbeeKit.h>

#import "VizbeeDemo-Swift.h"

@interface SettingsViewController ()
@property (strong, nonatomic) NSUserDefaults *defaults;
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.title = @"Demo App Help";
    self.defaults = [NSUserDefaults standardUserDefaults];
    
     [Vizbee addCastIconToNavigationItem:self.navigationItem withViewController:self];
}

//---------------------------------------
#pragma mark - TableView Delegate Methods
//---------------------------------------

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Conversion flows
    // SmartHelp
    if (indexPath.section == 0) {
        
        // clear states for testing so that card shows evey time
        if (indexPath.row == 0) {
            // cast introduction flow
            if ([self.defaults objectForKey:@"vzb_any_card"]) {
                [self.defaults removeObjectForKey:@"vzb_any_card"];
            }
        } else if (indexPath.row == 1) {
            
            // smart install flow
            NSDateComponents *dateComponents = [NSDateComponents new];
            dateComponents.day = -31;
            NSDate *date = [[NSCalendar currentCalendar]
                            dateByAddingComponents:dateComponents
                            toDate: [NSDate date]
                            options:0];
            [self.defaults setValue:date forKey:@"vzb_any_card"];
            [self.defaults setValue:date forKey:@"vzb_smart_install_card"];
            [self.defaults synchronize];
        }
        
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
    } else if (indexPath.section == 1) {
        
        if (indexPath.row == 0) {
            
            // send message
            MobileToTVMessager* mobileToTVMessager = VizbeeWrapper.shared.mobileToTVMessager;
            if ([mobileToTVMessager isConnectedToTV]) {
                [mobileToTVMessager sendWithEventName:mobileToTVMessager.kEventName 
                                                 data:[mobileToTVMessager getMessage]];
            } else {
                NSLog(@"Vizbee::SettingsViewController:didSelectRowAtIndexPath - Not connected to the TV to send the message");
            }
        }
    }
}

@end
