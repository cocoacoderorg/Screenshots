//
//  EAGLView.m
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




#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#import "EAGLView.h"


@interface EAGLView (PrivateMethods)
- (void)createFramebuffer;
- (void)deleteFramebuffer;

@end



@implementation EAGLView


@synthesize context;

@synthesize openGLPicture;
@synthesize openGLScreenshotImage;



#pragma mark -
#pragma mark OpenGL View Init Methods

//
// You must implement this method.
//
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}



//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:.
- (id)initWithCoder:(NSCoder*)coder
{
//    NSLog(@"EAGLView -initWithCoder");
    self = [super initWithCoder:coder];
	if (self) 
    {
        CAEAGLLayer *eaglLayer          = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque                = FALSE;
        eaglLayer.drawableProperties    = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                           kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                           nil];
    }
    
    return self;
}

- (void)dealloc
{
    [self deleteFramebuffer];    
    [context release];
    
    [super dealloc];
}


- (EAGLContext *)context
{
//	NSLog(@"EAGLView -context");
    return context;
}



- (void)setContext:(EAGLContext *)newContext
{
//    NSLog(@"EAGLView -setContext");
    if (context != newContext) 
    {
//        NSLog(@"inside of setContext");
        [self deleteFramebuffer];
        
        [context release];
        context = [newContext retain];
        
        [EAGLContext setCurrentContext:nil];
    }
}



#pragma mark -
#pragma mark Buffer Methods
- (void)createFramebuffer
{
    if (context && !defaultFramebuffer) 
    {
        [EAGLContext setCurrentContext:context];
        
        // Create default framebuffer object.
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create color render buffer and allocate backing store.
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}




- (void)deleteFramebuffer
{
    if (context) {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer) 
        {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer) 
        {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
    }
}



- (void)setFramebuffer
{
    if (context) 
    {
        [EAGLContext setCurrentContext:context];
        
        if (!defaultFramebuffer)
            [self createFramebuffer];
        
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        glViewport(0, 0, framebufferWidth, framebufferHeight);
    }
}



- (BOOL)presentFramebuffer
{
    BOOL success = FALSE;
    
    if (context) 
    {
        [EAGLContext setCurrentContext:context];
        
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        success = [context presentRenderbuffer:GL_RENDERBUFFER];
    }
    
    return success;
}



- (void)layoutSubviews
{
    // The framebuffer will be re-created at the beginning of the next setFramebuffer method call.
    [self deleteFramebuffer];
}




#pragma mark -
#pragma mark OpenGL Screenshot Methods
- (void)openGLViewScreenshot:(UIView*)eaglview
{
//	NSLog(@"Just took an OpenGL picture");
	
	
    // Get the size of the backing CAEAGLLayer
    GLint backingWidth, backingHeight;
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
    NSInteger x = 0;
    NSInteger y = 0; 
    NSInteger width = backingWidth;
    NSInteger height = backingHeight;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
	
    // Read pixel data from the framebuffer
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
	
    // Create a CGImage with the pixel data
    // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
    // otherwise, use kCGImageAlphaPremultipliedLast
    CGDataProviderRef ref           = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace      = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref                 = CGImageCreate(
                                                    width, 
                                                    height, 
                                                    8, 
                                                    32, 
                                                    width * 4, 
                                                    colorspace, 
                                                    kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    
	
    // OpenGL ES measures data in PIXELS
    // Create a graphics context with the target size measured in POINTS
    NSInteger widthInPoints; 
    NSInteger heightInPoints;
    if (NULL != UIGraphicsBeginImageContextWithOptions) {
        // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
        // Set the scale parameter to your OpenGL ES view's contentScaleFactor
        // so that you get a high-resolution snapshot when its value is greater than 1.0
        CGFloat scale       = eaglview.contentScaleFactor;
        widthInPoints       = width / scale;
        heightInPoints      = height / scale;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    }
    else {
        // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
        widthInPoints       = width;
        heightInPoints      = height;
        UIGraphicsBeginImageContext(CGSizeMake(widthInPoints, heightInPoints));
    }
	
    CGContextRef cgcontext  = UIGraphicsGetCurrentContext();
	
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    // Flip the CGImage by rendering it to the flipped bitmap context
    // The size of the destination area is measured in POINTS
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
	
    // Retrieve the UIImage from the current context
    UIImage *image          = UIGraphicsGetImageFromCurrentImageContext();
	
    UIGraphicsEndImageContext();
	
    // Clean up
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
	
	
	//
	// Set the resulting image to the openGLScreenshotImage image.
	//
	self.openGLScreenshotImage = image;
}



- (UIImage *)openGLScreenshot
{
	self.openGLPicture = YES;
	
	[self openGLViewScreenshot:self];
	
	return self.openGLScreenshotImage;
}


@end
