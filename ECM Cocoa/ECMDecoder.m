//
//  ECMDecoder.m
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import "ECMDecoder.h"

@implementation ECMDecoder {
	/* LUTs used for computing ECC/EDC */
	uint8_t ecc_f_lut[256];
	uint8_t ecc_b_lut[256];
	uint32_t edc_lut[256];
}
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
		_destinationURL = destURL;
		uint32_t i, j, edc;
		for(i = 0; i < 256; i++) {
			j = (i << 1) ^ (i & 0x80 ? 0x11D : 0);
			ecc_f_lut[i] = j;
			ecc_b_lut[i ^ j] = i;
			edc = i;
			for(j = 0; j < 8; j++) edc = (edc >> 1) ^ (edc & 1 ? 0xD8018001 : 0);
			edc_lut[i] = edc;
		}
	}
	return self;
}

static uint32_t edc_partial_computeblock(ECMDecoder *self,
								  uint32_t  edc,
								  const uint8_t  *src,
								  uint16_t  size)
{
	while(size--) edc = (edc >> 8) ^ self->edc_lut[(edc ^ (*src++)) & 0xFF];
	return edc;
}

/**
 * Compute EDC for a block
 */
-(void) computeEDCBlockWithSource:(const uint8_t*) src
							 size:(uint16_t) size
					  destination:(uint8_t*) dest
{
	uint32_t edc = edc_partial_computeblock(self, 0, src, size);
	dest[0] = (edc >>  0) & 0xFF;
	dest[1] = (edc >>  8) & 0xFF;
	dest[2] = (edc >> 16) & 0xFF;
	dest[3] = (edc >> 24) & 0xFF;
}

/**
 * Compute ECC for a block (can do either P or Q)
 */
static void ecc_computeblock(ECMDecoder *self,
							 uint8_t *src,
							 uint32_t major_count,
							 uint32_t minor_count,
							 uint32_t major_mult,
							 uint32_t minor_inc,
							 uint8_t *dest)
{
	uint32_t size = major_count * minor_count;
	uint32_t major, minor;
	for(major = 0; major < major_count; major++) {
		uint32_t index = (major >> 1) * major_mult + (major & 1);
		uint8_t ecc_a = 0;
		uint8_t ecc_b = 0;
		for(minor = 0; minor < minor_count; minor++) {
			uint8_t temp = src[index];
			index += minor_inc;
			if(index >= size) index -= size;
			ecc_a ^= temp;
			ecc_b ^= temp;
			ecc_a = self->ecc_f_lut[ecc_a];
		}
		ecc_a = self->ecc_b_lut[self->ecc_f_lut[ecc_a] ^ ecc_b];
		dest[major              ] = ecc_a;
		dest[major + major_count] = ecc_a ^ ecc_b;
	}
}

/**
 * Generate ECC P and Q codes for a block
 */
-(void) generateECCWithSector:(uint8_t *)sector
				  zeroAddress:(int)zeroaddress
{
	uint8_t address[4], i;
	/* Save the address and zero it out */
	if(zeroaddress) {
		for(i = 0; i < 4; i++) {
			address[i] = sector[12 + i];
			sector[12 + i] = 0;
		}
	}
	/* Compute ECC P code */
	ecc_computeblock(self, sector + 0xC, 86, 24,  2, 86, sector + 0x81C);
	/* Compute ECC Q code */
	ecc_computeblock(self, sector + 0xC, 52, 43, 86, 88, sector + 0x8C8);
	/* Restore the address */
	if(zeroaddress) for(i = 0; i < 4; i++) sector[12 + i] = address[i];
}

/**
 * Generate ECC/EDC information for a sector (must be 2352 = 0x930 bytes)
 * Returns 0 on success
 */
- (void) generateECCEDCWithSector:(uint8_t *)sector type:(int)type
{
	uint32_t i;
	switch(type) {
		case 1: /* Mode 1 */
			/* Compute EDC */
			[self computeEDCBlockWithSource:sector + 0x00 size:0x810 destination:sector + 0x810];
			/* Write out zero bytes */
			for(i = 0; i < 8; i++) sector[0x814 + i] = 0;
			/* Generate ECC P/Q codes */
			[self generateECCWithSector:sector zeroAddress:0];
			break;
		case 2: /* Mode 2 form 1 */
			/* Compute EDC */
			[self computeEDCBlockWithSource:sector + 0x10 size:0x808 destination:sector + 0x818];
			/* Generate ECC P/Q codes */
			[self generateECCWithSector:sector zeroAddress:1];
			break;
		case 3: /* Mode 2 form 2 */
			/* Compute EDC */
			[self computeEDCBlockWithSource:sector + 0x10 size:0x91C destination:sector + 0x92C];
			break;
	}
}

#define setcounter(val) _progress.completedUnitCount = val

- (void)main
{
	FILE *in = fopen(_sourceURL.fileSystemRepresentation, "rb");
	FILE *out = fopen(_destinationURL.fileSystemRepresentation, "wb");
	if (in == NULL || out == NULL) {
		if (in) {
			fclose(in);
		}
		if (out) {
			fclose(out);
		}
		return;
	}
	
	unsigned checkedc = 0;
	unsigned char sector[2352];
	unsigned type;
	unsigned num;
	fseek(in, 0, SEEK_END);
	_progress = [NSProgress discreteProgressWithTotalUnitCount:ftell(in)];
	fseek(in, 0, SEEK_SET);
	if(
	   (fgetc(in) != 'E') ||
	   (fgetc(in) != 'C') ||
	   (fgetc(in) != 'M') ||
	   (fgetc(in) != 0x00)
	   ) {
		fprintf(stderr, "Header not found!\n");
		goto corrupt;
	}
	for(;;) {
		int c = fgetc(in);
		int bits = 5;
		if(c == EOF) goto uneof;
		type = c & 3;
		num = (c >> 2) & 0x1F;
		while(c & 0x80) {
			c = fgetc(in);
			if(c == EOF) goto uneof;
			num |= ((unsigned)(c & 0x7F)) << bits;
			bits += 7;
		}
		if(num == 0xFFFFFFFF) break;
		num++;
		if(num >= 0x80000000) goto corrupt;
		if(!type) {
			while(num) {
				int b = num;
				if(b > 2352) b = 2352;
				if(fread(sector, 1, b, in) != b) goto uneof;
				checkedc = edc_partial_computeblock(self, checkedc, sector, b);
				fwrite(sector, 1, b, out);
				num -= b;
				setcounter(ftell(in));
			}
		} else {
			while(num--) {
				memset(sector, 0, sizeof(sector));
				memset(sector + 1, 0xFF, 10);
				switch(type) {
					case 1:
						sector[0x0F] = 0x01;
						if(fread(sector + 0x00C, 1, 0x003, in) != 0x003) goto uneof;
						if(fread(sector + 0x010, 1, 0x800, in) != 0x800) goto uneof;
						[self generateECCEDCWithSector:sector type:1];
						checkedc = edc_partial_computeblock(self, checkedc, sector, 2352);
						fwrite(sector, 2352, 1, out);
						setcounter(ftell(in));
						break;
					case 2:
						sector[0x0F] = 0x02;
						if(fread(sector + 0x014, 1, 0x804, in) != 0x804) goto uneof;
						sector[0x10] = sector[0x14];
						sector[0x11] = sector[0x15];
						sector[0x12] = sector[0x16];
						sector[0x13] = sector[0x17];
						[self generateECCEDCWithSector:sector type:2];
						checkedc = edc_partial_computeblock(self, checkedc, sector + 0x10, 2336);
						fwrite(sector + 0x10, 2336, 1, out);
						setcounter(ftell(in));
						break;
					case 3:
						sector[0x0F] = 0x02;
						if(fread(sector + 0x014, 1, 0x918, in) != 0x918) goto uneof;
						sector[0x10] = sector[0x14];
						sector[0x11] = sector[0x15];
						sector[0x12] = sector[0x16];
						sector[0x13] = sector[0x17];
						[self generateECCEDCWithSector:sector type:3];
						checkedc = edc_partial_computeblock(self, checkedc, sector + 0x10, 2336);
						fwrite(sector + 0x10, 2336, 1, out);
						setcounter(ftell(in));
						break;
				}
			}
		}
	}
	if(fread(sector, 1, 4, in) != 4) goto uneof;
	//fprintf(stderr, "Decoded %ld bytes -> %ld bytes\n", ftell(in), ftell(out));
	if((sector[0] != ((checkedc >>  0) & 0xFF)) ||
	   (sector[1] != ((checkedc >>  8) & 0xFF)) ||
	   (sector[2] != ((checkedc >> 16) & 0xFF)) ||
	   (sector[3] != ((checkedc >> 24) & 0xFF))) {
		fprintf(stderr, "EDC error (%08X, should be %02X%02X%02X%02X)\n",
				checkedc,
				sector[3],
				sector[2],
				sector[1],
				sector[0]
				);
		goto corrupt;
	}
	fprintf(stderr, "Done; file is OK\n");
	fclose(in);
	fclose(out);
	
	return;// 0;
uneof:
	fprintf(stderr, "Unexpected EOF!\n");
corrupt:
	fprintf(stderr, "Corrupt ECM file!\n");
	fclose(in);
	fclose(out);
	return;// 1;
}

@end
