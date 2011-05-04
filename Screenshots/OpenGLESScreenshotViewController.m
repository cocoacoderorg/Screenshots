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



#import "OpenGLESScreenshotViewController.h"
#import "EAGLView.h"

//#import <AVFoundation/AVFoundation.h>
//#import <CoreGraphics/CoreGraphics.h>
//#import <CoreVideo/CoreVideo.h>
//#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>
//#import <AssetsLibrary/AssetsLibrary.h>


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
@interface OpenGLESScreenshotViewController()

// OpenGL ES Properties
@property (nonatomic, retain) EAGLContext *eaglContext;
@property (nonatomic, assign) CADisplayLink *displayLink;

// OpenGL ES Methods
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

// Display Preview Methods
- (void)displayOpenGLScreenshotImage;

@end




@implementation OpenGLESScreenshotViewController

// From extension
@synthesize eaglContext;
@synthesize displayLink;
@synthesize animating;
@synthesize animationFrameInterval;

@synthesize mainView;
@synthesize overlayView;
@synthesize overlayImageView;
@synthesize backgroundImageView;

@synthesize screenshotImage;
@synthesize screenshotPictureView;
@synthesize screenshotPictureLabel;
@synthesize screenshotPictureImageView;

@synthesize eaglView;
@synthesize openGLScreenshotImage;

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
    [overlayImageView release];
    [backgroundImageView release];
	
	[screenshotImage release];
	[screenshotPictureView release];
	[screenshotPictureLabel release];
	[screenshotPictureImageView release];
    
	[eaglView release];
	[openGLScreenshotImage release];
	
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
    
    //    if (!aContext) 
    //    {
    //        aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    //    }
    
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

    self.overlayImageView.image = [UIImage imageNamed:@"iPhone4"];
    self.backgroundImageView.image = [UIImage imageNamed:@"Aurora"];
}



- (void)viewWillAppear:(BOOL)animated
{
    [self startAnimation];
    
    [super viewWillAppear:animated];
}



- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
    [super viewWillDisappear:animated];
}



- (void)viewDidUnload
{
	[super viewDidUnload];
    
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
	
    self.eaglContext = nil;	
    
    self.mainView = nil;
    self.overlayView = nil;
    self.overlayImageView = nil;
    self.backgroundImageView = nil;
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}




#pragma mark -
#pragma mark getOpenGLScreenshot Method is based on QA1704

- (IBAction)getOpenGLScreenshot
{
	self.openGLScreenshotImage = [self.eaglView openGLScreenshot];
	self.screenshotImage = self.openGLScreenshotImage;
	
	[self performSelector:@selector(displayOpenGLScreenshotImage) withObject:nil afterDelay:0.10];
}




#pragma mark -
#pragma mark Methods for Displaying Screenshots on a View and a Web View.

- (void)displayOpenGLScreenshotImage
{
	//
	// This is only for the demo.
	//
	self.screenshotPictureImageView.layer.minificationFilter = kCAFilterTrilinear;
	self.screenshotPictureImageView.layer.minificationFilterBias = 0.0;
	self.screenshotPictureImageView.image = self.eaglView.openGLScreenshotImage;	
	
	self.screenshotPictureLabel.text        = @"OpenGL Screenshot";
}



- (IBAction)showScreenshotWebView
{
    if (!self.screenshotWebView) 
    {
        self.screenshotWebView = [[ScreenshotWebViewController alloc] initWithNibName:@"ScreenshotWebView" bundle:nil];
        
    }
    
    self.screenshotWebView.delegate = self;
    
    self.screenshotWebView.documentationURL = [NSURL URLWithString:@"http://developer.apple.com/library/ios/#qa/qa2010/qa1704.html"];
    
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
        animationFrameInterval = frameInterval;
        
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
        self.displayLink = nil;
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
    
//    glClearColor(1.0f, 1.0f, 1.0f, 0.0f);
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
