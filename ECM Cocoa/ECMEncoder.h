//
//  ECMEncoder.h
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import <Foundation/Foundation.h>
#import "ECMClass.h"

@interface ECMEncoder : NSOperation <ECMClass>
- (instancetype)initWithSourceURL:(NSURL *)srcURL;
- (instancetype)initWithSourceURL:(NSURL *)srcURL destinationURL:(NSURL*)destURL;

@end
