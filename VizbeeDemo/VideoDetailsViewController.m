//
//  VideoDetailsViewController.m
//  VizbeeDemo
//
//  Created by Work on 5/23/19.
//  Copyright © 2019 Prashanth Pappu. All rights reserved.
//

#import "VideoDetailsViewController.h"
#import <VizbeeKit/VizbeeKit.h>
#import "VideoPlayer.h"
#import <QuartzCore/QuartzCore.h>

@interface VideoDetailsViewController () <VZBCastIconStateListener>

@property (weak, nonatomic) IBOutlet UIImageView *movieImageView;
@property (weak, nonatomic) IBOutlet UILabel *movieTitle;
@property (weak, nonatomic) IBOutlet UILabel *movieSubtitle;
@property (weak, nonatomic) IBOutlet UITextView *movieSummary;
@property (weak, nonatomic) IBOutlet UIButton *playButtonOutlet;

@property (strong, nonatomic) UIButton *customCastButton;
@property (strong, nonatomic) VZBCastIconProxy* castIconProxy;

@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) int counter;

@end

@implementation VideoDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.castIconProxy removeStateChangeListener:self];
}

-(void)setupView {
        
    [self addCustomCastIconToNavigationItem];
    [self listenForCastIconStateChanges];
    
    self.movieTitle.text = self.movie.title;
    self.movieSubtitle.text = self.movie.subTitle;
    [self.movieSummary setText:self.movie.longDescription];
    self.movieImageView.image = self.movie.image;
    self.navigationItem.title = self.movie.title;
    [self setupPlayButton];
}

-(void) addCustomCastIconToNavigationItem {
    
    self.customCastButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.customCastButton setImage:[UIImage imageNamed:@"CustomCastIconNotConnected"] forState:UIControlStateNormal];
    [self.customCastButton addTarget:self action:@selector(customButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.customCastButton sizeToFit]; // Adjust the button size based on content

    // Create a UIBarButtonItem with the custom button as its custom view
    UIBarButtonItem *customBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.customCastButton];

    // Assign the custom button to the navigation item
    self.navigationItem.rightBarButtonItem = customBarButtonItem;
}

// Action method for the custom cast button
- (void)customButtonTapped {
    [self.castIconProxy click:self];
}

-(void) listenForCastIconStateChanges {
    if (nil == self.castIconProxy) {
        self.castIconProxy = [Vizbee getCastIconProxy];
    }
    [self.castIconProxy addStateChangeListener:self];
    [self onStateChange:[self.castIconProxy getCastState]];
}

-(void) onStateChange:(VZBCastingState)state {
    switch (state) {
        case VZBCastingStateDeactivated:
        case VZBCastingStateUnavailable:
            self.customCastButton.hidden = YES;
            break;
        case VZBCastingStateDisconnected:
            self.customCastButton.hidden = NO;
            [self.customCastButton setImage:[UIImage imageNamed:@"CustomCastIconNotConnected"] forState:UIControlStateNormal];
            break;
        case VZBCastingStateConnecting:
            // show the connecting state as needed
            break;
        case VZBCastingStateConnected:
            self.customCastButton.hidden = NO;
            [self.customCastButton setImage:[UIImage imageNamed:@"CustomCastIconConnected"] forState:UIControlStateNormal];
            break;
        
        
            
        default:
            self.customCastButton.hidden = NO;
            break;
    }
}

- (IBAction)playButton:(id)sender {
    
    //---------------------------
    // [Vizbee Begin] - SmartPlay
    //---------------------------
    
    // NOTES:
    // Vizbee's "SmartPlay" API should preceed your calls to play video locally on the phone/tablet.
    // 1. If there are no TV devices nearby, this API will invoke 'doPlayOnPhone' and your
    // app should continue to play the video on the local device.
    // 2. Else, this API will show the smart play card and invokes 'didPlayOnTV'
    // when the mobile connects to the TV
    //
    
    // smartplay v2 api
    VZBRequest* request = [[VZBRequest alloc] initWithAppVideo:self.movie
                                                          GUID:self.movie.guid
                                                 startPosition:0];
    [request didPlayOnTV:^(VZBScreen *screen) {
        
        
        NSLog(@"Played on screen = %@", screen);
    }];
    [request doPlayOnPhone:^(VZBStatus *status) {
        
        if (status.code == VZBStatusCodeVideoExcludedFromSmartPlay) {
            // do action
            // return;
        }
        
        NSLog(@"Play on phone with status = %@", status);
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        // Register for the app entering background notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleDidEnterBackground)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
        
        __weak typeof(self) weakSelf = self;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                 repeats:YES
                                                   block:^(NSTimer * _Nonnull timer) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (weakSelf) {
                weakSelf.counter++;
                if (weakSelf.counter == 10) {
                    [weakSelf handleDidEnterBackground];
                }
            }
        }];
        
        [VideoPlayer playVideo:self.movie atPosition:0 presentingViewController:self];
    }];
    
    [Vizbee smartPlay:request presentingViewController:self];
      
    //------------------------------
    // [End] Vizbee Integration Code
    //------------------------------
}

// Method to handle the app entering background
-(void) handleDidEnterBackground {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)setupPlayButton {
    
    self.playButtonOutlet.layer.cornerRadius = 4;
    self.playButtonOutlet.clipsToBounds = YES;
}

#pragma mark - Helpers

- (UIColor *)averageColor {
    
    UIColor *finalizedColor;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char rgba[4];
    CGContextRef context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), self.movie.image.CGImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    if (rgba[3] > 0) {
        CGFloat alpha = ((CGFloat)rgba[3])/255.0;
        CGFloat multiplier = alpha/255.0;
        finalizedColor = [UIColor colorWithRed:((CGFloat)rgba[0])*multiplier
                                         green:((CGFloat)rgba[1])*multiplier
                                          blue:((CGFloat)rgba[2])*multiplier
                                         alpha:alpha];
    } else {
        finalizedColor = [UIColor colorWithRed:((CGFloat)rgba[0])/255.0
                                         green:((CGFloat)rgba[1])/255.0
                                          blue:((CGFloat)rgba[2])/255.0
                                         alpha:((CGFloat)rgba[3])/255.0];
    }
    
    size_t count = CGColorGetNumberOfComponents(finalizedColor.CGColor);
    const CGFloat *componentColors = CGColorGetComponents(finalizedColor.CGColor);
    
    CGFloat darknessScore = 0;
    if (count == 2) {
        darknessScore = (((componentColors[0]*255) * 299) + ((componentColors[0]*255) * 587) + ((componentColors[0]*255) * 114)) / 1000;
    } else if (count == 4) {
        darknessScore = (((componentColors[0]*255) * 299) + ((componentColors[1]*255) * 587) + ((componentColors[2]*255) * 114)) / 1000;
    }
    
    //Get all UIViews in self.view.subViews
    for (UIView *view in [self.view subviews]) {
        //Check if the view is of UILabel class
        if ([view isKindOfClass:[UILabel class]] || [view isKindOfClass:[UITextView class]]) {
            if ([view isKindOfClass:[UILabel class]]) {
                //Cast the view to a UILabel
                UILabel *label = (UILabel *)view;
                if (darknessScore >= 125) {
                    label.textColor = [UIColor blackColor];
                } else {
                    label.textColor = [UIColor whiteColor];
                }
            }
            if ([view isKindOfClass:[UITextView class]]) {
                //Cast the view to a UITextView
                UITextView *text = (UITextView *)view;
                if (darknessScore >= 125) {
                    text.textColor = [UIColor blackColor];
                } else {
                    text.textColor = [UIColor whiteColor];
                }
            }
        }
    }
    
    return finalizedColor;
}

@end
