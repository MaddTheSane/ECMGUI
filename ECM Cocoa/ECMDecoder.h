//
//  ECMDecoder.h
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import <Foundation/Foundation.h>
#import "ECMClass.h"

@interface ECMDecoder : NSOperation <ECMClass, NSProgressReporting>
- (instancetype)initWithSourceURL:(NSURL *)srcURL;
- (instancetype)initWithSourceURL:(NSURL *)srcURL destinationURL:(NSURL*)destURL;
@property (readonly, strong) NSError *error;
@property (readonly, strong) NSProgress *progress;
@end
