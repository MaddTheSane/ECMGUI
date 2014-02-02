//
//  ECMClass.h
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import <Foundation/Foundation.h>

@protocol ECMClass <NSObject>
- (instancetype)initWithSourceURL:(NSURL *)srcURL;
- (instancetype)initWithSourceURL:(NSURL *)srcURL destinationURL:(NSURL*)destURL;
- (void)run;
@end
