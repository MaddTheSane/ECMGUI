//
//  ECMEncoder.h
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import <Foundation/Foundation.h>
#import "ECMClass.h"

@interface ECMEncoder : NSOperation <ECMClass, NSProgressReporting>
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithSourceURL:(NSURL *)srcURL;
- (instancetype)initWithSourceURL:(NSURL *)srcURL destinationURL:(NSURL*)destURL NS_DESIGNATED_INITIALIZER;
@property (readonly, strong) NSError *error;
@property (readonly, strong) NSProgress *progress;

@end
