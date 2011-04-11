//
//  ScreenshotWebView.m
//  Screenshots
//
//  Created by James Hillhouse on 3/28/11.
//  Copyright 2011 PortableFrontier. All rights reserved.
//

#import "ScreenshotWebViewController.h"




@implementation ScreenshotWebViewController



@synthesize delegate;
@synthesize documentationWebView;
@synthesize documentationURL;




#pragma mark - init & dealloc methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
    }
    return self;
}



- (void)dealloc
{
    [documentationWebView release];
    
    [super dealloc];
}




#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.documentationWebView.scalesPageToFit       = YES;
    [self.documentationWebView loadRequest:[NSURLRequest requestWithURL:self.documentationURL]];
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.documentationWebView loadRequest:[NSURLRequest requestWithURL:self.documentationURL]];
}



- (void)viewWillDisappear:(BOOL)animated
{
    {
        if ( self.documentationWebView.loading ) 
        {
            [self.documentationWebView stopLoading];
        }
        self.documentationWebView.delegate         = nil;    // disconnect the delegate as the webview is hidden
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}



- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.documentationWebView                      = nil;
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}




#pragma mark - UIWebViewDelegate Methods

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    // starting the load, show the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}



- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // finished loading, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}



- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // load error, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // report the error inside the webview
    NSString* errorString = [NSString stringWithFormat:
                             @"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",
                             error.localizedDescription];
    [self.documentationWebView loadHTMLString:errorString baseURL:nil];
}




# pragma mark - Action Methods

- (IBAction)done
{
    [self.delegate screenshotWebViewControllerDidFinish:self];
}

@end
