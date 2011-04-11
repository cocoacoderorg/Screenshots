//
//  EAGLView.h
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

@class EAGLContext;


// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView
{
@private
    // The pixel dimensions of the CAEAGLLayer.
    GLint				framebufferWidth;
    GLint				framebufferHeight;
    
    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view.
    GLuint				defaultFramebuffer, colorRenderbuffer;
	
    // OpenGL Screenshot ivars
	BOOL				openGLPicture;
	UIImage				*openGLScreenshotImage;
}

@property (nonatomic, retain)						EAGLContext     *context;

// Properties for OpenGL Screenshot
@property											BOOL            openGLPicture;
@property (nonatomic, retain)						UIImage         *openGLScreenshotImage;


- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

// This is the method declaration that takes the OpenGL screenshot and is based on QA1704.//
- (void)openGLViewScreenshot:(UIView*)eaglview;

// This is the method used to trigger OpenGL to take a screenshot.
- (UIImage *)openGLScreenshot;

@end
