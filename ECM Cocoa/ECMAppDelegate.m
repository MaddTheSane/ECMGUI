//
//  ECMAppDelegate.m
//  ECM GUI
//
//  Created by C.W. Betts on 5/14/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "ECMAppDelegate.h"


@implementation ECMAppDelegate

- (IBAction)selectFile:(id)sender
{
	NSOpenPanel *op = [[NSOpenPanel openPanel] retain];
	[op setCanChooseFiles:YES];
	[op setCanChooseDirectories:NO];
	[op setAllowsMultipleSelection:NO];
	if ([op runModal] == NSOKButton)
	{
		if(fileURL != nil)
			[fileURL release];
		fileURL = [[[op URLs] objectAtIndex:0] retain];
		[fileField setTitleWithMnemonic:[fileURL path]]; 
	}
	
	[op release];
}

- (void)dealloc
{
	[fileURL release];
	[super dealloc];
}
		
- (IBAction)beginConversion:(id)sender
{
	NSBundle *appBundle = [NSBundle mainBundle];
	NSString *toolName;
	if([conversionType selectedRow] == 0)
		toolName = @"ecm";
	else
		toolName = @"unecm";
	
	NSString *helperPath = [[appBundle resourcePath] stringByAppendingPathComponent:toolName];
	NSTask *theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:helperPath];
	[theTask setArguments:[NSArray arrayWithObject:[fileURL path]]];
	[statusText setTitleWithMnemonic:NSLocalizedString(@"Processing file", @"")];
	[theTask launch];
	[fileSelect setEnabled:NO];
	[beginButton setEnabled:NO];
	[theTask waitUntilExit];
	[fileSelect setEnabled:YES];
	[beginButton setEnabled:YES];
	[statusText setTitleWithMnemonic:NSLocalizedString(@"Ready", @"")];
	[theTask release];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

@end
