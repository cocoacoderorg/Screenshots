//
//  UIKitScreenshot.m
//  Screenshots
//
//  Created by James Hillhouse on 3/22/11.
//  Copyright 2011 PortableFrontier. All rights reserved.
//



//
// Hi,
//
// Disclaimer: This code has been modified from code from Apple in QA1702, QA1703, QA1704, and QA1714.
//
// The code does not come with any guarantees, warrantees, or even vague promises that it will work
// for you. It might. And if it does, then I am very happy, as I am sure you are. If it does not, then
// my apologies. Should you make any changes to this code to make it work better, please email those 
// changes to me at jimhillhouse@me.com so that others might benefit as the code evolves into something
// better than what I could construct.
//
// Thanks and good luck,
//
// Jim
//
//
//
// REVIEW OF APPLE SUPPLIED TECHNICAL DOCUMENTATION IN SUPPORT OF SCREEN/IMAGE CAPTURE
//
//
// In Technical Q&A 1702 "How to capture video frames from the camera as images using AV Foundation",
//
// http://developer.apple.com/library/ios/#qa/qa2010/qa1702.html
//
// Apple shows how to capture video frames from the camera as images using AV Foundation.
//
//
// In Technical Q&A 1703 "Screen Capture in UIKit Applications",
//
// http://developer.apple.com/library/ios/#qa/qa2010/qa1703.html
//
// Apple shows how to take a screenshot in an UIKit application.
//
//
// In Technical Q&A 1704 "OpenGL ES View Snapshot",
//
// http://developer.apple.com/library/ios/#qa/qa2010/qa1714.html
//
// Apple demonstrates how to take a snapshot of my OpenGL ES view and save the result in a UIImage. 
//
//
// In Technical Q&A 1714 "Capturing an image using AV Foundation",
//
// http://developer.apple.com/library/ios/#qa/qa2010/qa1714.html
//
// Apple pretty clearly shows how to programmatically take a screenshot of an app that contains both UIKit and Camera elements. 
//
//
// This demo application demonstrates how to use these solutions in combination to accomplish screen capture in an augmented
// reality environment with or without an OpenGL layer and does so using solutions not mentioned in the Technical Q&A's but 
// none-the-less a part of AVFoundation's AVCaptureSession's AVCaptureConnection,
//
// http://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVCaptureConnection_Class/Reference/Reference.html
//
// 



#import "UIKitScreenshotViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>


//
// View Controller Class Extension
//
@interface UIKitScreenshotViewController()

// Display Preview Methods
- (void)displayScreenshotImage;
- (UIImage *)uikitScreenshot;

@end




@implementation UIKitScreenshotViewController



@synthesize mainView;
@synthesize overlayView;
@synthesize overlayImageView;
@synthesize backgroundImageView;

@synthesize screenshotImage;
@synthesize screenshotPictureView;
@synthesize screenshotPictureLabel;
@synthesize screenshotPictureImageView;

@synthesize screenshotWebView;




#pragma mark - init & dealloc Methods

- (void)dealloc
{
    [mainView release];
	[overlayView release];
    [overlayImageView release];
    [backgroundImageView release];
	
	[screenshotImage release];
	[screenshotPictureView release];
	[screenshotPictureLabel release];
	[screenshotPictureImageView release];
    
    [screenshotWebView release];
    
    [super dealloc];
}




#pragma mark - View Lifecycle Methods

//
// I won't implement loadView to create a view hierarchy programmatically without using a nib.
//
- (void)viewDidLoad
{
	[super viewDidLoad];
    
    self.overlayImageView.image = [UIImage imageNamed:@"iPhone4"];
    self.backgroundImageView.image = [UIImage imageNamed:@"Aurora"];
}


- (void)viewDidUnload
{
	[super viewDidUnload];
    
    self.mainView = nil;
    self.overlayView = nil;
    self.overlayImageView = nil;
    self.backgroundImageView.image = nil;
}




#pragma mark - Other View Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}




#pragma mark - UIKit Screenshot Methods

- (IBAction)getUIKitScreenshot
{
	self.screenshotPictureView = nil;
	self.screenshotImage = [self uikitScreenshot];
	
	[self performSelector:@selector(displayScreenshotImage) withObject:nil afterDelay:0.10];
	self.screenshotPictureLabel.text = @"UIKit Screenshot";
}




#pragma mark -
#pragma mark screenshot Method is based on QA1703

- (UIImage *)uikitScreenshot 
{
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
	
    CGContextRef context = UIGraphicsGetCurrentContext();
	
    //
    // Iterate over every window from back to front.
    //
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            //
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context.
            //
            CGContextSaveGState(context);
            
            
            //
            // Center the context around the window's anchor point.
            //
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            
            
            //
            // Apply the window's transform about the anchor point.
            //
            CGContextConcatCTM(context, [window transform]);
            
            
            //
            // Offset by the portion of the bounds left of and above the anchor point.
            //
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
			
            
            //
            // Render the layer hierarchy to the current context.
            //
            [[window layer] renderInContext:context];
			
            
            //
            // Restore the context.
            //
            CGContextRestoreGState(context);
        }
    }
	
    
    //
    // Retrieve the screenshot image.
    //
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	
    UIGraphicsEndImageContext();
	
    return image;
}




#pragma mark -
#pragma mark Methods for Displaying Screenshots on a View and a Web View.

- (void)displayScreenshotImage
{
	//
	// screenshotPictureImageView is the view containing the screen shot image
	//
	self.screenshotPictureImageView.layer.minificationFilter = kCAFilterTrilinear;
	self.screenshotPictureImageView.layer.minificationFilterBias = 0.0;
	self.screenshotPictureImageView.image = self.screenshotImage;	
	
	self.screenshotPictureLabel.text = @"UIKit Screenshot";
}



- (IBAction)showScreenshotWebView
{
    if (!self.screenshotWebView) 
    {
        self.screenshotWebView = [[ScreenshotWebViewController alloc] initWithNibName:@"ScreenshotWebView" bundle:nil];

    }

    self.screenshotWebView.delegate = self;
    
    self.screenshotWebView.documentationURL = [NSURL URLWithString:@"http://developer.apple.com/library/ios/#qa/qa2010/qa1703.html"];
    	
	self.screenshotWebView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:self.screenshotWebView animated:YES];
}



- (void)screenshotWebViewControllerDidFinish:(ScreenshotWebViewController *)controller
{
	[self dismissModalViewControllerAnimated:YES];
}


@end
