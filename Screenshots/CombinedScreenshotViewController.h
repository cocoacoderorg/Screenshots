//
//  OpenGLES_1_2_TestViewController.h
//  OpenGLES_1_2_Test
//
//  Created by James Hillhouse on 12/13/10.
//  Copyright 2010 PortableFrontier. All rights reserved.
//



//
// Hi,
//
// Disclaimer: This code has been modified from code supplied by Apple in QA1703, QA1704, and QA1714.
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



#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#import "EAGLView.h"

#import "ScreenshotWebViewController.h"



@interface CombinedScreenshotViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, ScreenshotWebViewControllerDelegate>
{
@private
    // OpenGL ES ivars
    EAGLContext                 *eaglContext;
    GLuint                      program;
    
    BOOL                        animating;
    NSInteger                   animationFrameInterval;
    CADisplayLink               *displayLink;
    
@public
//    CAReplicatorLayer *replicator;
//	CAReplicatorLayer *replicatorX;
//	CAReplicatorLayer *replicatorY;
//	
//    CALayer *rootLayer;
//	CALayer *subLayer;
    
    UIView                      *mainView;
    UIView *SecondView;
	UIView                      *overlayView;
    UIImageView                 *backgroundImageView;
    
    // OpenGL Screenshot ivars
	EAGLView                    *eaglView;
	UIImage                     *openGLScreenshotImage;

	
    AVCaptureSession            *capturedSession;
    AVCaptureVideoPreviewLayer  *previewLayer;
    AVCaptureStillImageOutput	*capturedStillImageOutput;
	AVCaptureVideoOrientation	orientation;
    
    BOOL                        scanning;
    BOOL                        showMenuBar;
    
    ScreenshotWebViewController *screenshotWebView;
}
// Private OpenGL ES Properties
@property (readonly, nonatomic, getter=isAnimating) BOOL                        animating;
@property (nonatomic)                               NSInteger                   animationFrameInterval;

@property (nonatomic, retain)		IBOutlet		UIView                      *mainView;
@property (nonatomic, retain) IBOutlet UIView *SecondView;
@property (nonatomic, retain)		IBOutlet		UIView                      *overlayView;
@property (nonatomic, retain)       IBOutlet        UIImageView                 *backgroundImageView;

// Properties for Preview Image and Views
@property (nonatomic, retain)						UIImage                     *screenshotImage;
@property (nonatomic, retain)		IBOutlet		UIView                      *screenshotPictureView;
@property (nonatomic, retain)		IBOutlet		UILabel                     *screenshotPictureLabel;
@property (nonatomic, retain)		IBOutlet		UIImageView                 *screenshotPictureImageView;

// Properties for OpenGL Screenshot
@property (nonatomic, retain)		IBOutlet		EAGLView                    *eaglView;
@property (nonatomic, retain)						UIImage                     *openGLScreenshotImage;

// Properties for AVFoundation (camera) Screenshot
@property (nonatomic, retain)						AVCaptureSession			*capturedSession;
@property (nonatomic, retain)                       AVCaptureVideoPreviewLayer  *previewLayer;
@property (nonatomic, retain)						AVCaptureStillImageOutput	*capturedStillImageOutput;
@property (nonatomic,assign)						AVCaptureVideoOrientation	orientation;

@property (nonatomic, retain)		IBOutlet		UIButton                    *scanButton;
@property (nonatomic, retain)		IBOutlet		UIButton                    *cameraButton;

@property											BOOL                        scanning;
@property                                           BOOL                        showMenuBar;

@property (nonatomic, retain)                       ScreenshotWebViewController *screenshotWebView;


// OpenGL ES Methods
- (void)startAnimation;
- (void)stopAnimation;

// Screenshot Camera Methods
- (IBAction)setupCamera;
- (IBAction)scan;
- (IBAction)menuBar;

- (IBAction)showScreenshotWebView;

@end
