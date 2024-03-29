//
//  AppDelegate.m
//  VCode
//
//  Created by Joey Hagedorn on 3/27/08.
//  Copyright 2008 University of Illinois & Joey Hagedorn. All rights reserved.
//	This software is licensed under a BSD license. Please refer to the included
//  license file for more details.

#import "AppDelegate.h"


@implementation AppDelegate

- (void)dealloc
{	
    [super dealloc];
}


- (IBAction)btnVData:(id)sender {
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"VData" bundle:nil];
	NSLog(@"Vdata Launched");
   
    [nib instantiateNibWithOwner:self topLevelObjects:nil];
    [_secondWindow makeKeyAndOrderFront:nil];
    
    [nib release];
}
- (IBAction)btnVCode:(id)sender {
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"CodingDocument" bundle:nil];
	NSLog(@"Vcode Launched");
  
    [nib instantiateNibWithOwner:self topLevelObjects:nil];
    [_secondWindow makeKeyAndOrderFront:nil];
    
    [nib release];
}


- (BOOL) applicationShouldOpenUntitledFile: (NSApplication *)sender {
	return NO;
}

- (IBAction)openHelpPDF:(id)sender{
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"VCodeVDataDocs" ofType:@"pdf"]
							withApplication:@"Preview"];	
}


@end
