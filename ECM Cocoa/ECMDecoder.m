//
//  ECMDecoder.m
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import "ECMDecoder.h"

@implementation ECMDecoder
@synthesize sourceURL=_sourceURL;
@synthesize destinationURL=_destinationURL;

- (instancetype)initWithSourceURL:(NSURL *)srcURL
{
	return [self initWithSourceURL:srcURL destinationURL:[srcURL URLByDeletingPathExtension]];
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
	task.launchPath = [[NSBundle mainBundle] pathForResource:@"unecm" ofType:nil];
	task.arguments = @[_sourceURL.path, _destinationURL.path];
	[task launch];
	[task waitUntilExit];
}

@end
