//
//  ECMEncoder.m
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import "ECMEncoder.h"

@implementation ECMEncoder {
	/* LUTs used for computing ECC/EDC */
	uint8_t ecc_f_lut[256];
	uint8_t ecc_b_lut[256];
	uint32_t edc_lut[256];
	unsigned char inputqueue[1048576 + 4];

}
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
		_destinationURL = destURL;
		uint32_t i, j, edc;
		for(i = 0; i < 256; i++) {
			j = (i << 1) ^ (i & 0x80 ? 0x11D : 0);
			ecc_f_lut[i] = j;
			ecc_b_lut[i ^ j] = i;
			edc = i;
			for (j = 0; j < 8; j++) {
				edc = (edc >> 1) ^ (edc & 1 ? 0xD8018001 : 0);
			}
			edc_lut[i] = edc;
		}
	}
	return self;
}

#pragma mark -

/**
 * Compute EDC for a block
 */
-(uint32_t)computeEDCBlock:(uint32_t)edc
				withSource:(const uint8_t*) src
					  size:(uint16_t) size
{
	while(size--) edc = (edc >> 8) ^ edc_lut[(edc ^ (*src++)) & 0xFF];
	return edc;
}

/**
 * Compute ECC for a block (can do either P or Q)
 */
- (BOOL)computeECCBlockWithSource:(uint8_t*)src majorCount:(uint32_t)major_count
					   minorCount:(uint32_t)minor_count majorMult:(uint32_t)major_mult
				   minorIncrement:(uint32_t)minor_inc destination:(uint8_t *)dest
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
			ecc_a = ecc_f_lut[ecc_a];
		}
		ecc_a = ecc_b_lut[ecc_f_lut[ecc_a] ^ ecc_b];
		if(dest[major              ] != (ecc_a        )) return NO;
		if(dest[major + major_count] != (ecc_a ^ ecc_b)) return NO;
	}
	return YES;
}

/*
** Generate ECC P and Q codes for a block
*/
- (BOOL)generateECCWithSector:(uint8_t *)sector
				  zeroAddress:(int)zeroaddress
				  destination:(uint8_t *)dest
{
	BOOL r;
	uint8_t address[4], i;
	/* Save the address and zero it out */
	if(zeroaddress) {
		for(i = 0; i < 4; i++) {
			address[i] = sector[12 + i];
			sector[12 + i] = 0;
		}
	}
	/* Compute ECC P code */
	if(!([self computeECCBlockWithSource:sector + 0xC majorCount:86 minorCount:24 majorMult:2 minorIncrement:86 destination:dest + 0x81C - 0x81C])) {
		if(zeroaddress) {
			for(i = 0; i < 4; i++) {
				sector[12 + i] = address[i];
			}
		}
		return NO;
	}
	/* Compute ECC Q code */
	r = [self computeECCBlockWithSource:sector + 0xC majorCount:52 minorCount:43 majorMult:86 minorIncrement:88 destination:dest + 0x8C8 - 0x81C];
	/* Restore the address */
	if(zeroaddress) {
		for(i = 0; i < 4; i++) {
			sector[12 + i] = address[i];
		}
	}
	return r;
}

#pragma mark -

/*
** sector types:
** 00 - literal bytes
** 01 - 2352 mode 1         predict sync, mode, reserved, edc, ecc
** 02 - 2336 mode 2 form 1  predict redundant flags, edc, ecc
** 03 - 2336 mode 2 form 2  predict redundant flags, edc
*/

- (int)checkTypeWithSector:(unsigned char *)sector canBeType1:(BOOL)canbetype1
{
	BOOL canbetype2 = YES;
	BOOL canbetype3 = YES;
	uint32_t myedc;
	/* Check for mode 1 */
	if(canbetype1) {
		if((sector[0x00] != 0x00) ||
		   (sector[0x01] != 0xFF) ||
		   (sector[0x02] != 0xFF) ||
		   (sector[0x03] != 0xFF) ||
		   (sector[0x04] != 0xFF) ||
		   (sector[0x05] != 0xFF) ||
		   (sector[0x06] != 0xFF) ||
		   (sector[0x07] != 0xFF) ||
		   (sector[0x08] != 0xFF) ||
		   (sector[0x09] != 0xFF) ||
		   (sector[0x0A] != 0xFF) ||
		   (sector[0x0B] != 0x00) ||
		   (sector[0x0F] != 0x01) ||
		   (sector[0x814] != 0x00) ||
		   (sector[0x815] != 0x00) ||
		   (sector[0x816] != 0x00) ||
		   (sector[0x817] != 0x00) ||
		   (sector[0x818] != 0x00) ||
		   (sector[0x819] != 0x00) ||
		   (sector[0x81A] != 0x00) ||
		   (sector[0x81B] != 0x00)) {
			canbetype1 = NO;
		}
	}
	/* Check for mode 2 */
	if((sector[0x0] != sector[0x4]) ||
	   (sector[0x1] != sector[0x5]) ||
	   (sector[0x2] != sector[0x6]) ||
	   (sector[0x3] != sector[0x7])) {
		canbetype2 = NO;
		canbetype3 = NO;
		if(!canbetype1) return 0;
	}
	
	/* Check EDC */
	myedc = [self computeEDCBlock:0 withSource:sector size:0x808];
	if(canbetype2) {
		if((sector[0x808] != ((myedc >>  0) & 0xFF)) ||
		   (sector[0x809] != ((myedc >>  8) & 0xFF)) ||
		   (sector[0x80A] != ((myedc >> 16) & 0xFF)) ||
		   (sector[0x80B] != ((myedc >> 24) & 0xFF))) {
			canbetype2 = NO;
		}
	}
	myedc = [self computeEDCBlock:myedc withSource:sector +0x808 size:8];
	if(canbetype1) {
		if((sector[0x810] != ((myedc >>  0) & 0xFF)) ||
		   (sector[0x811] != ((myedc >>  8) & 0xFF)) ||
		   (sector[0x812] != ((myedc >> 16) & 0xFF)) ||
		   (sector[0x813] != ((myedc >> 24) & 0xFF))) {
			canbetype1 = NO;
		}
	}
	myedc = [self computeEDCBlock:myedc withSource:sector + 0x810 size:0x10C];
	if(canbetype3) {
		if((sector[0x91C] != ((myedc >>  0) & 0xFF)) ||
		   (sector[0x91D] != ((myedc >>  8) & 0xFF)) ||
		   (sector[0x91E] != ((myedc >> 16) & 0xFF)) ||
		   (sector[0x91F] != ((myedc >> 24) & 0xFF))) {
			canbetype3 = NO;
		}
	}
	/* Check ECC */
	if(canbetype1) {
		if(!([self generateECCWithSector:sector zeroAddress:0 destination:sector + 0x81C])) {
			canbetype1 = NO;
		}
	}
	if(canbetype2) {
		if(!([self generateECCWithSector:sector - 0x10 zeroAddress:1 destination:sector + 0x80C])) {
			canbetype2 = NO;
		}
	}
	if(canbetype1) return 1;
	if(canbetype2) return 2;
	if(canbetype3) return 3;
	return 0;
}

/**
 * Encode a type/count combo
 */
static void write_type_count(FILE *fout, unsigned type, unsigned count)
{
	count--;
	fputc(((count >= 32) << 7) | ((count & 31) << 2) | type, fout);
	count >>= 5;
	while(count) {
		fputc(((count >= 128) << 7) | (count & 127), fout);
		count >>= 7;
	}
}

#pragma mark -

#define setcounter_encode(val) _progress.completedUnitCount = val
#define setcounter_analyze(val)

/**
 * Encode a run of sectors/literals of the same type
 */
- (unsigned)inFlushWithEDC:(unsigned)edc type:(unsigned)type count:(unsigned)count fileIn:(FILE*)fin fileOut:(FILE*)fout
{
	unsigned char buf[2352];
	write_type_count(fout, type, count);
	if(!type) {
		while(count) {
			unsigned b = count;
			if(b > 2352) b = 2352;
			fread(buf, 1, b, fin);
			edc = [self computeEDCBlock:edc withSource:buf size:b];
			fwrite(buf, 1, b, fout);
			count -= b;
			setcounter_encode(ftell(fin));
		}
		return edc;
	}
	while(count--) {
		switch(type) {
			case 1:
				fread(buf, 1, 2352, fin);
				edc = [self computeEDCBlock:edc withSource:buf size:2352];
				fwrite(buf + 0x00C, 1, 0x003, fout);
				fwrite(buf + 0x010, 1, 0x800, fout);
				setcounter_encode(ftell(fin));
				break;
			case 2:
				fread(buf, 1, 2336, fin);
				edc = [self computeEDCBlock:edc withSource:buf size:2336];
				fwrite(buf + 0x004, 1, 0x804, fout);
				setcounter_encode(ftell(fin));
				break;
			case 3:
				fread(buf, 1, 2336, fin);
				edc = [self computeEDCBlock:edc withSource:buf size:2336];
				fwrite(buf + 0x004, 1, 0x918, fout);
				setcounter_encode(ftell(fin));
				break;
		}
	}
	return edc;
}

- (void)main
{
	FILE *fin = fopen(_sourceURL.fileSystemRepresentation, "rb");
	FILE *fout = fopen(_destinationURL.fileSystemRepresentation, "wb");
	if (fin == NULL || fout == NULL) {
		if (fin) {
			fclose(fin);
		}
		if (fout) {
			fclose(fout);
		}
		return;
	}
	
	unsigned inedc = 0;
	int curtype = -1;
	int curtypecount = 0;
	int curtype_in_start = 0;
	int detecttype;
	int incheckpos = 0;
	long inbufferpos = 0;
	long intotallength;
	int inqueuestart = 0;
	size_t dataavail = 0;
	int typetally[4];
	fseek(fin, 0, SEEK_END);
	intotallength = ftell(fin);
	_progress = [NSProgress discreteProgressWithTotalUnitCount:intotallength];
	typetally[0] = 0;
	typetally[1] = 0;
	typetally[2] = 0;
	typetally[3] = 0;
	/* Magic identifier */
	fputc('E', fout);
	fputc('C', fout);
	fputc('M', fout);
	fputc(0x00, fout);
	for(;;) {
		if ((dataavail < 2352) && (dataavail < (intotallength - inbufferpos))) {
			long willread = intotallength - inbufferpos;
			if (willread > ((sizeof(inputqueue) - 4) - dataavail)) {
				willread = (sizeof(inputqueue) - 4) - dataavail;
			}
			if(inqueuestart) {
				memmove(inputqueue + 4, inputqueue + 4 + inqueuestart, dataavail);
				inqueuestart = 0;
			}
			if(willread) {
				setcounter_analyze(inbufferpos);
				fseek(fin, inbufferpos, SEEK_SET);
				fread(inputqueue + 4 + dataavail, 1, willread, fin);
				inbufferpos += willread;
				dataavail += willread;
			}
		}
		if(dataavail <= 0) {
			break;
		}
		if(dataavail < 2336) {
			detecttype = 0;
		} else {
			detecttype = [self checkTypeWithSector:inputqueue + 4 + inqueuestart canBeType1:dataavail >= 2352];
		}
		if (detecttype != curtype) {
			if (curtypecount) {
				fseek(fin, curtype_in_start, SEEK_SET);
				typetally[curtype] += curtypecount;
				inedc = [self inFlushWithEDC:inedc type:curtype count:curtypecount fileIn:fin fileOut:fout];
			}
			curtype = detecttype;
			curtype_in_start = incheckpos;
			curtypecount = 1;
		} else {
			curtypecount++;
		}
		switch(curtype) {
			case 0: incheckpos +=    1; inqueuestart +=    1; dataavail -=    1; break;
			case 1: incheckpos += 2352; inqueuestart += 2352; dataavail -= 2352; break;
			case 2: incheckpos += 2336; inqueuestart += 2336; dataavail -= 2336; break;
			case 3: incheckpos += 2336; inqueuestart += 2336; dataavail -= 2336; break;
		}
	}
	if(curtypecount) {
		fseek(fin, curtype_in_start, SEEK_SET);
		typetally[curtype] += curtypecount;
		inedc = [self inFlushWithEDC:inedc type:curtype count:curtypecount fileIn:fin fileOut:fout];
	}
	/* End-of-records indicator */
	write_type_count(fout, 0, 0);
	/* Input file EDC */
	fputc((inedc >>  0) & 0xFF, fout);
	fputc((inedc >>  8) & 0xFF, fout);
	fputc((inedc >> 16) & 0xFF, fout);
	fputc((inedc >> 24) & 0xFF, fout);
	fclose(fout);
	fclose(fin);
}

@end
