//
//  RootViewController.m
//  Screenshots
//
//  Created by James Hillhouse on 3/22/11.
//  Copyright 2011 PortableFrontier. All rights reserved.
//

#import "ScreenshotsRootViewController.h"

#import "UIKitScreenshotViewController.h"
#import "OpenGLESScreenshotViewController.h"
#import "AVFoundationScreenshotViewController.h"
#import "CombinedScreenshotViewController.h"

@implementation ScreenshotsRootViewController



@synthesize viewControllers;

@synthesize uikitScreenshotViewController;
@synthesize opengGLESScreenshotViewController;
@synthesize avfoundationScreenshotViewController;
@synthesize combinedScreenshotViewController;

@synthesize screenshotsTableViewCell;
@synthesize screenshotName;
@synthesize screenshotSummary;




#pragma mark - init & dealloc Methods

- (void)dealloc
{
    [viewControllers release];
    
    [uikitScreenshotViewController release];
    [opengGLESScreenshotViewController release];
    [avfoundationScreenshotViewController release];
    [combinedScreenshotViewController release];
    
    [screenshotsTableViewCell release];
    [screenshotName release];
    [screenshotSummary release];
    
    [super dealloc];
}



#pragma mark - UITableView Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDictionary    *screenshotDictionary1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"UIKit Screenshot", @"Name",
                                                   @"As documented in Apple's QA1703", @"Summary", nil];
 
    NSDictionary    *screenshotDictionary2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"OpenGL ES Screenshot", @"Name",
                                                   @"As documented in Apple's QA1704", @"Summary", nil];

    NSDictionary    *screenshotDictionary3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"AVFoundation Screenshot", @"Name",
                                                   @"As documented in Apple's QA1714", @"Summary", nil];
    
    NSDictionary    *screenshotDictionary4 = [[NSDictionary alloc] initWithObjectsAndKeys:@"Combined Screenshot", @"Name",
                                                   @"QA 1702, QA 1703, QA 1704 & QA1714", @"Summary", nil];
    
    NSArray         *anArray = [[NSArray alloc] initWithObjects:
                                screenshotDictionary1, 
                                screenshotDictionary2, 
                                screenshotDictionary3, 
                                screenshotDictionary4, nil];
    
    self.viewControllers = anArray;
    
    [screenshotDictionary1 release];
    [screenshotDictionary2 release];
    [screenshotDictionary3 release];
    [screenshotDictionary4 release];
    [anArray release];
}



- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.viewControllers = nil;
    
    self.uikitScreenshotViewController = nil;
    self.opengGLESScreenshotViewController = nil;
    self.avfoundationScreenshotViewController = nil;
    self.combinedScreenshotViewController = nil;
    
    self.screenshotsTableViewCell = nil;
    self.screenshotName = nil;
    self.screenshotSummary = nil;
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}



- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}



- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */


#pragma mark - UITableViewDelegate Methods

//
// Customize the number of sections in the table view.
//
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.viewControllers count];
}



//
// Customize the appearance of table view cells.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ScreenshotsCellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ScreenshotsCellIdentifier];
    if (cell == nil) 
    {
        NSArray    *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ScreenshotsTableViewCell" owner:self options:nil];
        
        if ( [nibArray count] > 0 ) 
        {
            cell = self.screenshotsTableViewCell;
        }
        else
        {
            NSLog(@"Uh oh, ScreenshotsTableViewCell nib file didn't load.");
        }
    }
    
    
    //
    // Using the selected table view row, configure the cell.
    //
    NSUInteger row = [indexPath row];
    NSDictionary *rowData = [self.viewControllers objectAtIndex:row];
    
    self.screenshotName.text = [rowData objectForKey:@"Name"];
    self.screenshotSummary.text = [rowData objectForKey:@"Summary"];
    
    return cell;
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 100;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    
    if ( row == 0 ) 
    {
        [self.navigationController pushViewController:self.uikitScreenshotViewController animated:YES];
    }
    
    if ( row == 1 ) 
    {
        [self.navigationController pushViewController:self.opengGLESScreenshotViewController animated:YES];
    }
    
    if ( row == 2 ) 
    {
        [self.navigationController pushViewController:self.avfoundationScreenshotViewController animated:YES];
    }
    
    if ( row == 3 ) 
    {
        [self.navigationController pushViewController:self.combinedScreenshotViewController animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}


@end
