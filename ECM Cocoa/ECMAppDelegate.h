//
//  ECMAppDelegate.h
//  ECM GUI
//
//  Created by C.W. Betts on 5/14/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ECMAppDelegate : NSObject {
	IBOutlet NSTextField *statusText;
	IBOutlet NSTextField *fileField;
	IBOutlet NSMatrix *conversionType;
	NSURL *fileURL;
}
- (IBAction)selectFile:(id)sender;
- (IBAction)beginConversion:(id)sender;

@end
