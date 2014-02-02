//
//  ECMEncoder.m
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import "ECMEncoder.h"

@implementation ECMEncoder

- (instancetype)initWithSourceURL:(NSURL *)srcURL
{
	return [self initWithSourceURL:srcURL destinationURL:[srcURL URLByAppendingPathExtension:@"ecm"]];
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
