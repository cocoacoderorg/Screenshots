//
//  OpenGLES_1_2_TestViewController.m
//  OpenGLES_1_2_Test
//
//  Created by James Hillhouse on 12/13/10.
//  Copyright 2010 PortableFrontier. All rights reserved.
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



#import "AVFoundationScreenshotViewController.h"

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
@interface AVFoundationScreenshotViewController()

// Screenshot Methods
- (void)renderView:(UIView*)view inContext:(CGContextRef)context;
- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;

// AVFoundation (Camera) Methods
- (void)setupCaptureSession;
- (void)captureStillImage;
- (void)captureStillImageFailedWithError:(NSError *)error;
- (void)cannotWriteToAssetLibrary;
- (void)cameraOn;
- (void)cameraOff;

// Display Preview Methods
- (void)displayScreenshotImage;

@end




@implementation AVFoundationScreenshotViewController



@synthesize mainView;
@synthesize overlayView;
@synthesize overlayImageView;
@synthesize backgroundImageView;

@synthesize capturedSession;
@synthesize previewLayer;
@synthesize capturedStillImageOutput;
@synthesize orientation;

@synthesize scanButton;
@synthesize cameraButton;

@synthesize screenshotImage;
@synthesize screenshotPictureView;
@synthesize screenshotPictureLabel;
@synthesize screenshotPictureImageView;

@synthesize scanning;

@synthesize screenshotWebView;



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
    
    [capturedSession release];
    [previewLayer release];
    
    [screenshotWebView release];

    [super dealloc];
}


#pragma mark -
#pragma mark UIView Controller Methods

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    self.overlayImageView.image                 = [UIImage imageNamed:@"iPhone4"];
    self.backgroundImageView.image              = [UIImage imageNamed:@"Aurora"];
    
    
	self.scanning								= NO;
	self.cameraButton.selected					= NO;
	self.scanButton.selected					= NO;
	
	//
	// These UIButton calls set up the custom button to change its appearance when selected/not selected.
	//
	[self.scanButton setTitle:@"Stop" forState:UIControlStateSelected];
	[self.scanButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
	
	[self.scanButton setTitle:@"Take a Picture!" forState:UIControlStateNormal];
	[self.scanButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];	
	
	//
	// These UIButton calls set up the custom button to change its appearance when selected/not selected.
	//
	[self.cameraButton setTitle:@"Cancel" forState:UIControlStateSelected];
	[self.cameraButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
	
	[self.cameraButton setTitle:@"Camera" forState:UIControlStateNormal];
	[self.cameraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}



- (void)viewWillDisappear:(BOOL)animated
{
    [self cameraOff];
    
    [super viewWillDisappear:animated];
}



- (void)viewDidUnload
{
	[super viewDidUnload];
    
    self.mainView                               = nil;
    self.overlayView                            = nil;
    self.overlayImageView                       = nil;
    self.backgroundImageView                    = nil;
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}







#pragma mark -
#pragma mark Methods for OpenGL & UIKView Screenshots based on Q&A 1702, Q&A 1703, Q&A 1704, & Q&A 1714

- (void)renderView:(UIView*)view inContext:(CGContextRef)context
{
	//////////////////////////////////////////////////////////////////////////////////////
	//																					//
	// This works like a charm when you have multiple views that need to be rendered	//
	// in a UIView when one of those views is an OpenGL CALayer view or a camera stream	//
	// or some other view that will not work with - (UIImage*)screenshot, as defined 	//
	// in Technical Q&A QA1703, "Screen Capture in UIKit Applications".					//
	//																					//
	//////////////////////////////////////////////////////////////////////////////////////
	
	
	//
	// -renderInContext: renders in the coordinate space of the layer,
    // so we must first apply the layer's geometry to the graphics context.
	//
    CGContextSaveGState(context);
    
	
	//
	// Center the context around the window's anchor point.
	//
    CGContextTranslateCTM(context, [view center].x, [view center].y);
    
	
	//
	// Apply the window's transform about the anchor point.
	//
    CGContextConcatCTM(context, [view transform]);
	
	
	//
    // Offset by the portion of the bounds left of and above the anchor point.
	//
    CGContextTranslateCTM(context,
                          -[view bounds].size.width * [[view layer] anchorPoint].x,
                          -[view bounds].size.height * [[view layer] anchorPoint].y);
    
	
	//
	// Render the layer hierarchy to the current context.
	//
    [[view layer] renderInContext:context];
	
    
	//
	// Restore the context. BTW, you're done.
	//
    CGContextRestoreGState(context);
}




#pragma mark -
#pragma mark IBAction Methods for Camera and Scanning

- (IBAction)setupCamera
{
	if (!self.cameraButton.selected) 
	{
		[self cameraOn];
	}
	else 
	{
		[self cameraOff];
	}
}



- (void)cameraOn
{
	self.cameraButton.selected					= YES;
	
	CGPoint newCameraButtonCenter				= self.cameraButton.center;
	newCameraButtonCenter.x						= 94.0;
	
	CGPoint	newScanButtonCenter					= self.scanButton.center;
	newScanButtonCenter.x						= 226.0;
    
	//
	// Translate the cameraButton and scanButton using view animation
	//
	[UIView animateWithDuration:0.75 animations:^{
		self.cameraButton.center				= newCameraButtonCenter;
		self.scanButton.center					= newScanButtonCenter;
		
		self.scanButton.layer.opacity			= 1.0;
	}];
	
	[self setupCaptureSession];
    
    //
    // Remove the background image so that the streaming camera video will be visable.
    //
    self.backgroundImageView.image              = nil;
	
	//
	// This creates the preview of the camera
	//
	self.previewLayer                           = [AVCaptureVideoPreviewLayer layerWithSession:self.capturedSession];
	
    self.previewLayer.frame						= self.backgroundImageView.bounds; // Assume you want the preview layer to fill the view.
    
    if (self.previewLayer.orientationSupported) 
    {
        self.previewLayer.orientation           = AVCaptureVideoOrientationPortrait;
    }
    
    self.previewLayer.videoGravity              = AVLayerVideoGravityResizeAspectFill;
	[self.backgroundImageView.layer addSublayer:self.previewLayer];				
}



- (void)cameraOff
{
	self.cameraButton.selected					= NO;
	
	CGPoint newCameraButtonCenter				= self.cameraButton.center;
	newCameraButtonCenter.x						= 160.0;
	
	CGPoint	newScanButtonCenter					= self.scanButton.center;
	newScanButtonCenter.x						= 160.0;
	
	//
	// Translate the cameraButton and scanButton using view animation
	//
	[UIView animateWithDuration:0.75 animations:^{
		self.cameraButton.center				= newCameraButtonCenter;
		self.scanButton.center					= newScanButtonCenter;
		
		self.scanButton.layer.opacity			= 0.0;
		
        //
        // This resets the background to an image since the previewLayer is no longer getting content from the camera.
        //
		self.backgroundImageView.image          = [UIImage imageNamed:@"Aurora"];
	}];
	
	
	[self.capturedSession stopRunning];	
    [self.previewLayer removeFromSuperlayer];
    
}



- (IBAction)scan
{
//	NSLog(@"Scanning");
	
	self.scanning									= YES;
	self.scanButton.selected						= YES;
    
    [UIView animateWithDuration:0.1 animations:^{
        
	}
					 completion:^( BOOL finished ){
						 if (finished) 
						 {
							 [self captureStillImage];
						 }
					 }];
    
}



// Create and configure a capture session and start it running
- (void)setupCaptureSession 
{
//	NSLog(@"setupCaptureSession");
	
    NSError *error = nil;
	
	//
    // Create the session
	//
    AVCaptureSession *session					= [[AVCaptureSession alloc] init];
	
	//
    // Configure the session to produce lower resolution video frames, if your 
    // processing algorithm can cope. We'll specify medium quality for the
    // chosen device.
	//
    session.sessionPreset						= AVCaptureSessionPreset640x480;
	
    //
	// Find a suitable AVCaptureDevice
	//
    AVCaptureDevice *device						= [AVCaptureDevice
												   defaultDeviceWithMediaType:AVMediaTypeVideo];
	
	//
	// Support auto-focus locked mode
	//
	if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) 
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error]) {
			device.focusMode					= AVCaptureFocusModeAutoFocus;
			[device unlockForConfiguration];
		}
		else 
		{
			// Respond to the failure as appropriate.
		}
	}
	
	//
	// Support auto flash mode
	//
	if ([device isFlashModeSupported:AVCaptureFlashModeAuto]) 
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error]) {
			device.flashMode					= AVCaptureFlashModeAuto;
			[device unlockForConfiguration];
		}
		else 
		{
			// Respond to the failure as appropriate.
		}
	}	
	
	//
    // Create a device input with the device and add it to the session.
	//
    AVCaptureDeviceInput *input					= [AVCaptureDeviceInput deviceInputWithDevice:device 
																			error:&error];
    if (!input) 
	{
        // Handling the error appropriately.
    }
    [session addInput:input];
	
	//
    // Create a AVCaputreStillImageOutput instance and add it to the session
	//
	AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
	[stillImageOutput setOutputSettings:outputSettings];
	
	
	[session addOutput:stillImageOutput];
	
	//
	// This is what actually gets the AVCaptureSession going
	//
    [session startRunning];
	
	//
    // Assign session we've created here to our AVCaptureSession ivar.
	//
	// KEY POINT: With this AVCaptureSession property, you can start/stop scanning to your hearts content, or 
	// until the code you are trying to read has read it.
	//
	self.capturedStillImageOutput				= stillImageOutput;
	self.capturedSession						= session;
}



#pragma mark -
#pragma mark Screenshot Methods Using AVFoundation and UIKit as shown in Technical Q&A 1714

- (void) captureStillImage
{
    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[self.capturedStillImageOutput connections]];
	
    if ([videoConnection isVideoOrientationSupported]) 
	{
		[videoConnection setVideoOrientation:[[UIDevice currentDevice] orientation]]; 
	}
	
    [self.capturedStillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
															   completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) 
     {
         // 
         // If this line is not commented-out, the animationWithDuration:animations:^ never gets called. Weird...
         //
         if (imageDataSampleBuffer != NULL) 
         {
             NSData *imageData					= [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
             
             UIImage *image						= [[UIImage alloc] initWithData:imageData];
             
             //
             // Now, we're going to using -renderView:inContext to build-up our screenshot.
             //
             //
             // Create a graphics context with the target size
             //
             CGSize imageSize = [[UIScreen mainScreen] bounds].size;
             UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
             
             CGContextRef context				= UIGraphicsGetCurrentContext();
             
             //
             // Draw the image returned by the camera sample buffer into the context. 
             // Draw it into the same sized rectangle as the view that is displayed on the screen.
             //
             //			CGFloat menubarUIOffset				= 20.0;
             //			CGFloat	tabbarUIOffset				= 44.0;
             UIGraphicsPushContext(context);
             [image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
             UIGraphicsPopContext();
             
             
             //
             // Render the camera overlay view into the graphic context that we created above.
             //
             [self renderView:self.overlayView inContext:context];
             
             //
             // Retrieve the screenshot image containing both the camera content and the overlay view
             //
             UIImage *screenshot					= UIGraphicsGetImageFromCurrentImageContext();
             
             self.screenshotImage                   = screenshot;
             
             UIGraphicsEndImageContext();
             
             UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil);
             
             
             //
             // Comment-out this call if you're not using it for the demo.
             //
             [self performSelector:@selector(displayScreenshotImage) withObject:nil afterDelay:0.10];

             UIGraphicsEndImageContext();
             
             //
             // This is one way to get images into the Photos Library.
             //
             //UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil);
             
             //
             // Now write the final screenshot output to the users images
             //
             
             ALAssetsLibrary *library			= [[ALAssetsLibrary alloc] init];
             
             [library writeImageToSavedPhotosAlbum:[screenshot CGImage]
                                       orientation:ALAssetOrientationUp
                                   completionBlock:^(NSURL *assetURL, NSError *error)
              {
                  if (error) 
                  {
                      if ([self respondsToSelector:@selector(captureStillImageFailedWithError:)]) 
                      {
                          [self captureStillImageFailedWithError:error];
                      }                                                                                               
                  }
              }];
             
             [library release];
             
             [image release];
         } 
         else if (error) 
         {
             NSLog(@"Oops!");
             if ([self respondsToSelector:@selector(captureStillImageFailedWithError:)]) 
             {
                 [self captureStillImageFailedWithError:error];
             }
         }
     }];
	
	// 
	// Clean-up a bit here
	//
	self.scanning								= NO;
	self.scanButton.selected					= NO;
}



- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
	for ( AVCaptureConnection *connection in connections ) 
	{
		for ( AVCaptureInputPort *port in [connection inputPorts] ) 
		{
			if ( [[port mediaType] isEqual:mediaType] ) 
			{
				return [[connection retain] autorelease];
			}
		}
	}
	return nil;
}




#pragma mark -
#pragma mark Error Handling Methods

- (void) captureStillImageFailedWithError:(NSError *)error
{
    UIAlertView *alertView						= [[UIAlertView alloc] initWithTitle:@"Still Image Capture Failure"
															 message:[error localizedDescription]
															delegate:nil
												   cancelButtonTitle:@"Okay"
												   otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}



- (void) cannotWriteToAssetLibrary
{
    UIAlertView *alertView						= [[UIAlertView alloc] initWithTitle:@"Incompatible with Asset Library"
															 message:@"The captured file cannot be written to the asset library. It is likely an audio-only file."
															delegate:nil
												   cancelButtonTitle:@"Okay"
												   otherButtonTitles:nil];
    [alertView show];
    [alertView release];        
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
	
	self.screenshotPictureLabel.text = @"AVFoundation Screenshot";
}



- (IBAction)showScreenshotWebView
{
    if (!self.screenshotWebView) 
    {
        self.screenshotWebView = [[ScreenshotWebViewController alloc] initWithNibName:@"ScreenshotWebView" bundle:nil];
        
    }
    
    self.screenshotWebView.delegate = self;
    
    self.screenshotWebView.documentationURL     = [NSURL URLWithString:@"http://developer.apple.com/library/ios/#qa/qa2010/qa1714.html"];
    
	self.screenshotWebView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:self.screenshotWebView animated:YES];
}



- (void)screenshotWebViewControllerDidFinish:(ScreenshotWebViewController *)controller
{
	[self dismissModalViewControllerAnimated:YES];
}


@end
