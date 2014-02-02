//
//  ECMDecoder.m
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import "ECMDecoder.h"

@implementation ECMDecoder

- (instancetype)initWithSourceURL:(NSURL *)srcURL
{
	return [self initWithSourceURL:srcURL destinationURL:[srcURL URLByDeletingPathExtension]];
}

- (instancetype)initWithSourceURL:(NSURL *)srcURL destinationURL:(NSURL*)destURL
{
	if (self = [super init]) {
		
	}
	return self;
}

- (void)run
{
	
}

@end
