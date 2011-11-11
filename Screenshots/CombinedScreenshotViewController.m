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



#import "CombinedScreenshotViewController.h"
#import "EAGLView.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>


// Uniform index.
enum 
{
    UNIFORM_TRANSLATE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum 
{
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
    NUM_ATTRIBUTES
};


//
// View Controller Class Extension
//
@interface CombinedScreenshotViewController()

// OpenGL ES Properties
@property (nonatomic, retain) EAGLContext *eaglContext;
@property (nonatomic, assign) CADisplayLink *displayLink;

// OpenGL ES Methods
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

// UIKit Screenshot Methods
- (void)renderView:(UIView*)view inContext:(CGContextRef)context;

// Display Preview Methods
- (void)displayScreenshotImage;

// AVFoundation (Camera) Methods
- (void)cameraOn;
- (void)cameraOff;
- (void)setupCaptureSession;
- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
- (void)captureStillImage;
- (void)autofocusNotSupported;
- (void)flashNotSupported;
- (void)captureStillImageFailedWithError:(NSError *)error;
- (void)cannotWriteToAssetLibrary;

@end




@implementation CombinedScreenshotViewController



@synthesize capturedSession;
@synthesize previewLayer;
@synthesize capturedStillImageOutput;
@synthesize orientation;

//@synthesize openGLPicture;
@synthesize openGLScreenshotImage;

@synthesize eaglView;
@synthesize mainView;
@synthesize SecondView;
@synthesize overlayView;
@synthesize backgroundImageView;

@synthesize scanButton;
@synthesize cameraButton;

@synthesize screenshotImage;
@synthesize screenshotPictureView;
@synthesize screenshotPictureLabel;
@synthesize screenshotPictureImageView;

@synthesize scanning;
@synthesize showMenuBar;

// From extension
@synthesize eaglContext;
@synthesize displayLink;
@synthesize animating;
@synthesize animationFrameInterval;

@synthesize screenshotWebView;



- (void)dealloc
{
    if (program) 
    {
        glDeleteProgram(program);
        program = 0;
    }
    
    // Tear down context.
    if ([EAGLContext currentContext] == eaglContext)
    {
        [EAGLContext setCurrentContext:nil];
    }

    [eaglContext release];
    [displayLink release];
    
	[mainView release];
	[overlayView release];
    [backgroundImageView release];
	
	[screenshotImage release];
	[screenshotPictureView release];
	[screenshotPictureLabel release];
	[screenshotPictureImageView release];
 	
	[eaglView release];
	[openGLScreenshotImage release];
   
    [capturedSession release];
    [previewLayer release];

    [SecondView release];
    [super dealloc];
}


/*
- (void)awakeFromNib
{
    NSLog(@"-awakeFromNib");
//    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    EAGLContext *aContext                        = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!aContext) 
    {
        aContext                                = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    }
    
    if (!aContext)
    {
        NSLog(@"Failed to create ES context");
    }
    else if (![EAGLContext setCurrentContext:aContext])
    {
        NSLog(@"Failed to set ES context current");
    }
    
	self.eaglContext                             = aContext;
	[aContext release];
	
    [self.eaglView setContext:self.eaglContext];
    [self.eaglView setFramebuffer];
    
    if ([eaglContext API] == kEAGLRenderingAPIOpenGLES2)
    {
        [self loadShaders];
    }
    
    animating                                   = FALSE;
    animationFrameInterval                      = 1;
    self.displayLink                            = nil;
}
*/



#pragma mark -
#pragma mark UIView Controller Methods

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    
    //
    // OpenGL ES code originally in -awakeFromNib
    //
    //    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    //if (!aContext) 
    //{
    //  aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    //}
    
    if (!aContext)
    {
        NSLog(@"Failed to create ES context");
    }
    else if (![EAGLContext setCurrentContext:aContext])
    {
        NSLog(@"Failed to set ES context current");
    }
    
	self.eaglContext = aContext;
	[aContext release];
	
    [self.eaglView setContext:self.eaglContext];
    [self.eaglView setFramebuffer];
    
    
    //    if ([eaglContext API] == kEAGLRenderingAPIOpenGLES2)
    //    {
    //        [self loadShaders];
    //    }
    
    animating = FALSE;
    animationFrameInterval = 1;
    self.displayLink = nil;
    
    self.backgroundImageView.image = [UIImage imageNamed:@"Aurora"];
    
	self.scanning = NO;
    self.showMenuBar = NO;
	
    
    self.cameraButton.selected = NO;
	self.scanButton.selected = NO;
	
	
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
    [self startAnimation];
    
    [super viewWillAppear:animated];
}



- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
    [self cameraOff];
    
    [super viewWillDisappear:animated];
}



- (void)viewDidUnload
{
    [self setSecondView:nil];
	[super viewDidUnload];
    
    if (program) 
    {
        glDeleteProgram(program);
        program = 0;
    }
    
    
    //
    // Tear down context.
    //
    if ([EAGLContext currentContext] == eaglContext)
    {
        [EAGLContext setCurrentContext:nil];
    }
	self.eaglContext = nil;	
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}




#pragma mark -
#pragma mark screenshot Method is based on QA1703

- (UIImage*)screenshot 
{
    //
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext.
    //
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    if (NULL != UIGraphicsBeginImageContextWithOptions)
    {
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    }
    else
    {
        UIGraphicsBeginImageContext(imageSize);
	}
    
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
#pragma mark Screenshot Methods Using AVFoundation and UIKit as shown in Technical Q&A 1714

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
    //
    // The camera has been selected.
    //
	self.cameraButton.selected = YES;
	
    
    //
    // Set the camera and scan button frame centers to the new desired centers.
    //
	CGPoint newCameraButtonCenter = self.cameraButton.center;
	newCameraButtonCenter.x = 94.0;
	
	CGPoint	newScanButtonCenter = self.scanButton.center;
	newScanButtonCenter.x = 226.0;
    
    
    //
	// Translate the cameraButton and scanButton using view animation with a completion block.
	//
	[UIView animateWithDuration:0.75 animations:^{
		self.cameraButton.center = newCameraButtonCenter;
		self.scanButton.center = newScanButtonCenter;
		
		self.scanButton.layer.opacity = 1.0;
	}];
	
	[self setupCaptureSession];
    
    
    //
    // Remove the background image so that the streaming camera video will be visable.
    //
    self.backgroundImageView.image = nil;
	
	
    //
	// This creates the preview of the camera
	//
	self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.capturedSession];
    self.previewLayer.frame = self.backgroundImageView.bounds; // Assume you want the preview layer to fill the view.
    
    
    //
    // Set the previewLayer to portrait.
    //
    if (self.previewLayer.orientationSupported) 
    {
        self.previewLayer.orientation = AVCaptureVideoOrientationPortrait;
    }
    
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    
    //
    // Set the previewLayer as a sublayer of the backgroundImageView's layer
    //
	[self.backgroundImageView.layer addSublayer:self.previewLayer];	
    

    /*
    
    //Create the root layer
	rootLayer = [CALayer layer];
	
    //Create the replicator layer
	replicatorX = [CAReplicatorLayer layer];
	
	//Set the replicator's attributes
	replicatorX.frame = self.backgroundImageView.frame;

    //Create the second level of replicators
	replicatorY = [CAReplicatorLayer layer];
	
    replicatorY.frame = self.SecondView.frame;
    
    //Create a sublayer
	subLayer = [CALayer layer];
    subLayer.frame = self.SecondView.frame;
    subLayer = self.previewLayer;
    
    //Set up the sublayer/replicator hierarchy
	[replicatorY addSublayer:subLayer];
	[replicatorX addSublayer:replicatorY];
	
	//Add the replicator to the root layer
	[rootLayer addSublayer:replicatorX];
	
	//Set the view's layer to the base layer
	[self.backgroundImageView.layer addSublayer:rootLayer];
	
	//Force the view to update
	//[self.backgroundImageView setNeedsDisplay:YES];
     */
}



- (void)cameraOff
{
    //
    // Camera is now off.
    //
	self.cameraButton.selected = NO;
	
	
    //
    // Set the camera and scan button frame centers to the new desired centers.
    //
	CGPoint newCameraButtonCenter = self.cameraButton.center;
	newCameraButtonCenter.x = 160.0;
	
	CGPoint	newScanButtonCenter = self.scanButton.center;
	newScanButtonCenter.x = 160.0;
	
	
    //
	// Translate the cameraButton and scanButton using view animation with a completion block.
	//
	[UIView animateWithDuration:0.75 animations:^{
		self.cameraButton.center = newCameraButtonCenter;
		self.scanButton.center = newScanButtonCenter;
		
		self.scanButton.layer.opacity = 0.0;
		
        
        //
        // This resets the background to an image since the previewLayer is no longer getting content from the camera.
        //
		self.backgroundImageView.image = [UIImage imageNamed:@"Aurora"];
	}];
	
	
	[self.capturedSession stopRunning];	
    [self.previewLayer removeFromSuperlayer];
    
}



// Create and configure a capture session and start it running
- (void)setupCaptureSession 
{
//	NSLog(@"setupCaptureSession");
	
    NSError *error = nil;
	
	
    //
    // Create the session
	//
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
	
	
    //
    // Configure the session to produce lower resolution video frames, if your 
    // processing algorithm can cope. We'll specify medium quality for the
    // chosen device.
	//
    session.sessionPreset = AVCaptureSessionPreset640x480;
	
    
    //
	// Find a suitable AVCaptureDevice
	//
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	
	
    //
	// Support auto-focus locked mode
	//
	if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) 
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error]) 
        {
			device.focusMode    = AVCaptureFocusModeAutoFocus;
			[device unlockForConfiguration];
		}
		else 
		{
            NSLog(@"Oops!");
            if ([self respondsToSelector:@selector(autofocusNotSupported)]) 
            {
                [self autofocusNotSupported];
            }
		}
	}
	
	
    //
	// Support auto flash mode
	//
	if ([device isFlashModeSupported:AVCaptureFlashModeAuto]) 
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error]) 
        {
			device.flashMode = AVCaptureFlashModeAuto;
			[device unlockForConfiguration];
		}
		else 
		{
            NSLog(@"Oops!");
            if ([self respondsToSelector:@selector(flashNotSupported)]) 
            {
                [self flashNotSupported];
            }
		}
	}	
	
	
    //
    // Create a device input with the device and add it to the session.
	//
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device 
																			error:&error];
    if (!input) 
	{
        // Handling the error appropriately.
    }
    [session addInput:input];
	
	
    //
    // Create a AVCaputreStillImageOutput instance and add it to the session
	//
//	AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
//    self.capturedStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
	[self.capturedStillImageOutput setOutputSettings:outputSettings];
    [outputSettings release];
	
	
//	[session addOutput:stillImageOutput];
    [session addOutput:self.capturedStillImageOutput];
    
//    self.capturedStillImageOutput = stillImageOutput;
//    [stillImageOutput release];
	
	
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
//	self.capturedStillImageOutput = stillImageOutput;
//    [stillImageOutput release];

	self.capturedSession = session;
    [session release];
}



- (IBAction)scan
{
//	NSLog(@"Scanning");
	
	self.scanning = YES;
	self.scanButton.selected = YES;
    
    
    //
    // Trigger the OpenGL screenshot and scream-out how much you love blocks!
    //
    self.openGLScreenshotImage = [self.eaglView openGLScreenshot];
    
    [self performSelector:@selector(captureStillImage) withObject:nil afterDelay:0.1];
    
    [self performSelector:@selector(displayScreenshotImage) withObject:nil afterDelay:0.5];
    
}



- (IBAction)menuBar
{
    if (self.showMenuBar) 
    {
        self.showMenuBar = NO;
    }
    else
    {
        self.showMenuBar = YES;
    }
}



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
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
             
             UIImage *cameraImage = [[UIImage alloc] initWithData:imageData];
             
   
             //
             // Now, we're going to using -renderView:inContext to build-up our screenshot.
             //
             //
             // Create a graphics context with the target size
             //
             CGSize imageSize = [[UIScreen mainScreen] bounds].size;
             UIGraphicsBeginImageContextWithOptions( imageSize, NO, 0 );
             
             
             //
             // Set-up the context
             //
             CGContextRef context = UIGraphicsGetCurrentContext();
             
             
             //
             // This is so that the navigation bar is captured.
             //
             if (self.showMenuBar) 
             {
                 for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
                 {
                     [self renderView:window inContext:context];
                 }
             }

             
             /////////////////////////////////////////////////////////////////////////////////////
             //																					//
             //                   AVFoundation (Camera) Generated Image                         //
             //																					//
             /////////////////////////////////////////////////////////////////////////////////////
             //
             // Draw the image returned by the camera sample buffer into the context. 
             // Draw it into the same sized rectangle as the view that is displayed on the screen.
             //
             UIGraphicsPushContext(context);
             {
                 if (self.showMenuBar) 
                 {
                     //
                     // Adjust UI Items to reflect their size
                     //
                     CGFloat statusBarUIOffset = 20.0;
                     CGFloat navBarUIOffset = 44.0;
                     CGFloat offset = statusBarUIOffset + navBarUIOffset;
                   
                     [cameraImage drawInRect:CGRectMake( 0.0, offset, imageSize.width, imageSize.height - offset )];
                 }
                 else
                 {
                     [cameraImage drawInRect:CGRectMake( 0.0, 0.0, imageSize.width, imageSize.height )];
                 }
             }
             UIGraphicsPopContext();
  
             
             /////////////////////////////////////////////////////////////////////////////////////
             //																					//
             //                   AVFoundation + OpenGL ES Generated Image                      //
             //																					//
             /////////////////////////////////////////////////////////////////////////////////////
             //
             // Draw the image returned by the OpenGL ES render buffer
             // Draw it into the same sized rectangle a the view that is displayed on the screen.
             //
             // But do not forget to include the offsets so that the OpenGL ES view is proportionate
             // to its size.
             //
             CGSize openGLImageSize = CGSizeMake(openGLScreenshotImage.size.width, openGLScreenshotImage.size.height);
             CGFloat openGLImageOffsetX = ( imageSize.width - openGLImageSize.width ) / 2.0;
             CGFloat openGLImageOffsetY = ( imageSize.height - openGLImageSize.height ) / 2.0;

             UIGraphicsPushContext(context);
             {
                 [self.openGLScreenshotImage drawInRect:CGRectMake(openGLImageOffsetX, 
                                                                   openGLImageOffsetY, 
                                                                   openGLImageSize.width, 
                                                                   openGLImageSize.height)];
             }
             UIGraphicsPopContext();
             
             
             /////////////////////////////////////////////////////////////////////////////////////
             //																					//
             //         AVFoundation+ OpengGL ES + UIKit (Overview) Layer Generated Image       //
             //																					//
             /////////////////////////////////////////////////////////////////////////////////////
             //
             // Render the camera overlay view into the graphic context that we created above.
             //
             [self renderView:self.overlayView inContext:context];
             
             
             /////////////////////////////////////////////////////////////////////////////////////
             //																					//
             //              Completed Image from AVFoundation + OpenGL ES + UIKit              //
             //																					//
             /////////////////////////////////////////////////////////////////////////////////////
             //
             // Retrieve the screenshot image containing both the camera content and the overlay view
             //
             UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
//             CGSize finalImgSize = CGSizeMake(screenshot.size.width, screenshot.size.height);
             self.screenshotImage = screenshot;
             
             
             //
             // We're done with the image context, so close it out.
             //
             UIGraphicsEndImageContext();
             
             
             //
             // This is a quickie way to write images to the photo album. I'm keeping this code here for those who might
             // want to use this instead of the better method below
             //
             //UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil);
             
             
             //
             // Now write the final screenshot output to the users images
             //
             ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
             
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
             
             [cameraImage release];
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
	self.scanning = NO;
	self.scanButton.selected = NO;
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

- (void) autofocusNotSupported
{
    UIAlertView *alertView  = [[UIAlertView alloc] initWithTitle:@"Autofocus Not Supported On This Device"
                                                         message:@"Autofocus is not supported on your device. However, you can still use the camera."
                                                        delegate:nil
                                               cancelButtonTitle:@"Okay"
                                               otherButtonTitles:nil];
    [alertView show];
    [alertView release];        
}



- (void) flashNotSupported
{
    UIAlertView *alertView  = [[UIAlertView alloc] initWithTitle:@"No Flash Available On This Device"
                                                         message:@"Your device does not have a camera flash. However, you can still use the camera."
                                                        delegate:nil
                                               cancelButtonTitle:@"Okay"
                                               otherButtonTitles:nil];
    [alertView show];
    [alertView release];        
}



- (void) captureStillImageFailedWithError:(NSError *)error
{
    UIAlertView *alertView  = [[UIAlertView alloc] initWithTitle:@"Still Image Capture Failure"
                                                         message:[error localizedDescription]
                                                        delegate:nil
                                               cancelButtonTitle:@"Okay"
                                               otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}



- (void) cannotWriteToAssetLibrary
{
    UIAlertView *alertView  = [[UIAlertView alloc] initWithTitle:@"Incompatible with Asset Library"
                                                         message:@"The captured file cannot be written to the asset library. It is likely an audio-only file."
                                                        delegate:nil
                                               cancelButtonTitle:@"Okay"
                                               otherButtonTitles:nil];
    [alertView show];
    [alertView release];        
}



#pragma mark -
#pragma mark Methods for Displaying Screenshots on a View and a Web View

- (void)displayScreenshotImage
{
	//
	// screenshotPictureImageView is the view containing the screen shot image
	//
	self.screenshotPictureImageView.layer.minificationFilter = kCAFilterTrilinear;
	self.screenshotPictureImageView.layer.minificationFilterBias = 0.0;
	self.screenshotPictureImageView.image = self.screenshotImage;	
	
	self.screenshotPictureLabel.text = @"Combo Screenshot";
}



- (IBAction)showScreenshotWebView
{
    ScreenshotWebViewController *webViewController = [[ScreenshotWebViewController alloc] initWithNibName:@"ScreenshotWebView" bundle:nil];
    self.screenshotWebView = webViewController;
    
    [webViewController release];
    
    self.screenshotWebView.delegate = self;
    
    self.screenshotWebView.documentationURL = [NSURL URLWithString:@"http://developer.apple.com/library/ios/#qa/qa2010/qa1714.html"];
    
	self.screenshotWebView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:self.screenshotWebView animated:YES];
}



- (void)screenshotWebViewControllerDidFinish:(ScreenshotWebViewController *)controller
{
	[self dismissModalViewControllerAnimated:YES];
}




#pragma mark -
#pragma mark OpenGL ES Methods

//
// This is the template code from Apple's OpenGL ES Project.
//
- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}



- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    /*
	 Frame interval defines how many display frames must pass between each time the display link fires.
	 The display link will only fire 30 times a second when the frame internal is two on a display that refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second when the display refreshes at 60 times a second. A frame interval setting of less than one results in undefined behavior.
	 */
    if (frameInterval >= 1) 
    {
        animationFrameInterval  = frameInterval;
        
        if (animating) 
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}



- (void)startAnimation
{
//    NSLog(@"-startAnimation");
    if (!animating) 
    {
//        NSLog(@"animating was NO, now is YES");
        CADisplayLink *aDisplayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(drawFrame)];
        [aDisplayLink setFrameInterval:animationFrameInterval];
        [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = aDisplayLink;
        
        animating = TRUE;
    }
}



- (void)stopAnimation
{
//    NSLog(@"-stopAnimation");
    if (animating) 
    {
        [self.displayLink invalidate];
        self.displayLink    = nil;
        animating = FALSE;
    }
}



- (void)drawFrame
{
    [self.eaglView setFramebuffer];
    
    // Replace the implementation of this method to do your own custom drawing.
    static const GLfloat squareVertices[] = 
    {
        -0.5f, -0.33f,
         0.5f, -0.33f,
        -0.5f,  0.33f,
         0.5f,  0.33f,
    };
    
    static const GLubyte squareColors[] = 
    {
        255, 255,   0, 255,
          0, 255, 255, 255,
          0,   0,   0,   0,
        255,   0, 255, 255,
    };
    
    static float transY = 0.0f;
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    /*
    if ([eaglContext API] == kEAGLRenderingAPIOpenGLES2) 
    {
        // Use shader program.
        glUseProgram(program);
        
        // Update uniform value.
        glUniform1f(uniforms[UNIFORM_TRANSLATE], (GLfloat)transY);
        transY                                      += 0.075f;	
        
        // Update attribute values.
        glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
        glEnableVertexAttribArray(ATTRIB_VERTEX);
        glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, 1, 0, squareColors);
        glEnableVertexAttribArray(ATTRIB_COLOR);
        
        // Validate program before drawing. This is a good check, but only really necessary in a debug build.
        // DEBUG macro must be defined in your debug configurations if that's not already the case.
#if defined(DEBUG)
        if (![self validateProgram:program]) 
        {
            NSLog(@"Failed to validate program: %d", program);
            return;
        }
#endif
    } else 
     */
    {
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        
        glTranslatef(0.0f, (GLfloat)(sinf(transY)/2.0f), 0.0f);
        
        transY += 0.075f;
        
        glVertexPointer(2, GL_FLOAT, 0, squareVertices);
        glEnableClientState(GL_VERTEX_ARRAY);
        glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
        glEnableClientState(GL_COLOR_ARRAY);
    }
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////
    //                                                                                              //
    //                                                                                              //
    //                    OpenGL Screenshot Code in -drawView per Technical Q&A 1704                //
    //                                                                                              //
    //                                                                                              //
	//////////////////////////////////////////////////////////////////////////////////////////////////    
	//
	// This is where the OpenGL view's screenshot will be taken. This call was placed here because
	// Apple warned that taking a screenshot _after_ -presentFramBuffer could lead to serious 
	// performance issues.
	//
	if (self.eaglView.openGLPicture) 
	{
//		NSLog(@"Taking a pic in EAGLView");
		
		[self.eaglView openGLViewScreenshot:self.eaglView];
		
		self.eaglView.openGLPicture = NO;
	}
    
    [self.eaglView presentFramebuffer];
}



- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}



- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}



- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}



- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program, ATTRIB_COLOR, "color");
    
    // Link program.
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return FALSE;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_TRANSLATE] = glGetUniformLocation(program, "translate");
    
    // Release vertex and fragment shaders.
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}



@end
