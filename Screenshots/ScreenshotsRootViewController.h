//
//  RootViewController.h
//  Screenshots
//
//  Created by James Hillhouse on 3/22/11.
//  Copyright 2011 PortableFrontier. All rights reserved.
//

#import <UIKit/UIKit.h>


@class UIKitScreenshotViewController;
@class OpenGLESScreenshotViewController;
@class AVFoundationScreenshotViewController;
@class CombinedScreenshotViewController;


@interface ScreenshotsRootViewController : UITableViewController <UINavigationBarDelegate, UITableViewDelegate, UITableViewDataSource>
{
    UIKitScreenshotViewController           *uikitScreenshotViewController;
    OpenGLESScreenshotViewController        *opengGLESScreenshotViewController;
    AVFoundationScreenshotViewController    *avfoundationScreenshotViewController;
    CombinedScreenshotViewController        *combinedScreenshotViewController;
    
    UITableViewCell                         *screenshotsTableViewCell;
    UILabel                                 *screenshotName;
    UILabel                                 *screenshotSummary;
}

@property (nonatomic, retain)                       NSArray                                 *viewControllers;

@property (nonatomic, retain)       IBOutlet        UIKitScreenshotViewController           *uikitScreenshotViewController;
@property (nonatomic, retain)       IBOutlet        OpenGLESScreenshotViewController        *opengGLESScreenshotViewController;
@property (nonatomic, retain)       IBOutlet        AVFoundationScreenshotViewController    *avfoundationScreenshotViewController;
@property (nonatomic, retain)       IBOutlet        CombinedScreenshotViewController        *combinedScreenshotViewController;

@property (nonatomic, retain)       IBOutlet        UITableViewCell                         *screenshotsTableViewCell;
@property (nonatomic, retain)       IBOutlet        UILabel                                 *screenshotName;
@property (nonatomic, retain)       IBOutlet        UILabel                                 *screenshotSummary;


@end
