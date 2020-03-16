//
//  ECMEncoder.m
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import "ECMEncoder.h"

@implementation ECMEncoder
@synthesize sourceURL=_sourceURL;
@synthesize destinationURL=_destinationURL;

- (instancetype)initWithSourceURL:(NSURL *)srcURL
{
	return [self initWithSourceURL:srcURL destinationURL:[srcURL URLByAppendingPathExtension:@"ecm"]];
}

- (instancetype)initWithSourceURL:(NSURL *)srcURL destinationURL:(NSURL*)destURL
{
	if (self = [super init]) {
		_sourceURL = srcURL;
	}
	return self;
}

- (void)main
{
	NSTask *task = [[NSTask alloc] init];
	task.launchPath = [[NSBundle mainBundle] pathForResource:@"ecm" ofType:nil];
	task.arguments = @[_sourceURL.path, _destinationURL.path];
	[task launch];
	[task waitUntilExit];
}

@end
