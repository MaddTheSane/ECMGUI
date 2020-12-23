//
//  ECMClass.h
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import <Foundation/Foundation.h>

/* LUTs used for computing ECC/EDC */
extern const uint8_t ecc_f_lut[256];
extern const uint8_t ecc_b_lut[256];
extern const uint32_t edc_lut[256];


@protocol ECMClass <NSObject>
- (instancetype)initWithSourceURL:(NSURL *)srcURL;
- (instancetype)initWithSourceURL:(NSURL *)srcURL destinationURL:(NSURL*)destURL;
- (void)main;
@property (readonly, strong) NSURL *sourceURL;
@property (readonly, strong) NSURL *destinationURL;
@end
