//
//  ECMAppDelegate.h
//  ECM GUI
//
//  Created by C.W. Betts on 5/14/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ECMAppDelegate : NSObject <NSApplicationDelegate>
@property (weak) IBOutlet NSTextField *statusText;
@property (weak) IBOutlet NSTextField *fileField;
@property (weak) IBOutlet NSMatrix *conversionType;
@property (weak) IBOutlet NSButton *fileSelect;
@property (weak) IBOutlet NSButton *beginButton;
@property (strong) NSURL *fileURL;

- (IBAction)selectFile:(id)sender;
- (IBAction)beginConversion:(id)sender;

@end
