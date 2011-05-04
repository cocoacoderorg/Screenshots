//
//  ScreenshotWebView.h
//  Screenshots
//
//  Created by James Hillhouse on 3/28/11.
//  Copyright 2011 PortableFrontier. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ScreenshotWebViewControllerDelegate;


@interface ScreenshotWebViewController : UIViewController <UIWebViewDelegate>
{
    id <ScreenshotWebViewControllerDelegate>    delegate;
    UIWebView                                   *documentationWebView;
    NSURL                                       *documentationURL;
}

@property (nonatomic, assign)       id              <ScreenshotWebViewControllerDelegate>   delegate;
@property (nonatomic, retain)       IBOutlet        UIWebView                               *documentationWebView;
@property (nonatomic, retain)                       NSURL                                   *documentationURL;

- (IBAction)done;

@end


@protocol ScreenshotWebViewControllerDelegate

- (void)screenshotWebViewControllerDidFinish:(ScreenshotWebViewController *)controller;

@end

