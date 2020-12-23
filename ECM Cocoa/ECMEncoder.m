//
//  ECMEncoder.m
//  ECM GUI
//
//  Created by C.W. Betts on 2/2/14.
//
//

#import "ECMEncoder.h"

const uint8_t ecc_f_lut[256] = {0, 2, 4, 6, 8, 10, 12, 14, 16, 18,
	20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48, 50,
	52, 54, 56, 58, 60, 62, 64, 66, 68, 70, 72, 74, 76, 78, 80, 82,
	84, 86, 88, 90, 92, 94, 96, 98, 100, 102, 104, 106, 108, 110, 112,
	114, 116, 118, 120, 122, 124, 126, 128, 130, 132, 134, 136, 138,
	140, 142, 144, 146, 148, 150, 152, 154, 156, 158, 160, 162, 164,
	166, 168, 170, 172, 174, 176, 178, 180, 182, 184, 186, 188, 190,
	192, 194, 196, 198, 200, 202, 204, 206, 208, 210, 212, 214, 216,
	218, 220, 222, 224, 226, 228, 230, 232, 234, 236, 238, 240, 242,
	244, 246, 248, 250, 252, 254, 29, 31, 25, 27, 21, 23, 17, 19, 13,
	15, 9, 11, 5, 7, 1, 3, 61, 63, 57, 59, 53, 55, 49, 51, 45, 47,
	41, 43, 37, 39, 33, 35, 93, 95, 89, 91, 85, 87, 81, 83, 77, 79,
	73, 75, 69, 71, 65, 67, 125, 127, 121, 123, 117, 119, 113, 115,
	109, 111, 105, 107, 101, 103, 97, 99, 157, 159, 153, 155, 149,
	151, 145, 147, 141, 143, 137, 139, 133, 135, 129, 131, 189, 191,
	185, 187, 181, 183, 177, 179, 173, 175, 169, 171, 165, 167, 161,
	163, 221, 223, 217, 219, 213, 215, 209, 211, 205, 207, 201, 203,
	197, 199, 193, 195, 253, 255, 249, 251, 245, 247, 241, 243, 237,
	239, 233, 235, 229, 231, 225, 227};
const uint8_t ecc_b_lut[256] = {0, 244, 245, 1, 247, 3, 2, 246, 243, 7, 6, 242, 4,
	240, 241, 5, 251, 15, 14, 250, 12, 248, 249, 13, 8, 252, 253, 9, 255, 11, 10,
	254, 235, 31, 30, 234, 28, 232, 233, 29, 24, 236, 237, 25, 239, 27, 26, 238, 16,
	228, 229, 17, 231, 19, 18, 230, 227, 23, 22, 226, 20, 224, 225, 21, 203, 63, 62,
	202, 60, 200, 201, 61, 56, 204, 205, 57, 207, 59, 58, 206, 48, 196, 197, 49, 199,
	51, 50, 198, 195, 55, 54, 194, 52, 192, 193, 53, 32, 212, 213, 33, 215, 35, 34,
	214, 211, 39, 38, 210, 36, 208, 209, 37, 219, 47, 46, 218, 44, 216, 217, 45, 40,
	220, 221, 41, 223, 43, 42, 222, 139, 127, 126, 138, 124, 136, 137, 125, 120, 140,
	141, 121, 143, 123, 122, 142, 112, 132, 133, 113, 135, 115, 114, 134, 131, 119,
	118, 130, 116, 128, 129, 117, 96, 148, 149, 97, 151, 99, 98, 150, 147, 103, 102,
	146, 100, 144, 145, 101, 155, 111, 110, 154, 108, 152, 153, 109, 104, 156, 157,
	105, 159, 107, 106, 158, 64, 180, 181, 65, 183, 67, 66, 182, 179, 71, 70, 178,
	68, 176, 177, 69, 187, 79, 78, 186, 76, 184, 185, 77, 72, 188, 189, 73, 191, 75,
	74, 190, 171, 95, 94, 170, 92, 168, 169, 93, 88, 172, 173, 89, 175, 91, 90, 174,
	80, 164, 165, 81, 167, 83, 82, 166, 163, 87, 86, 162, 84, 160, 161, 85};
const uint32_t edc_lut[256] = {0, 2425422081, 2434859521, 28312320,
	2453734401, 47187200, 56624640, 2482046721, 2491484161, 68159744,
	94374400, 2503019265, 113249280, 2521894145, 2548108801, 124784384,
	2566983681, 160436480, 136319488, 2561741569, 188748800, 2614170881,
	2590053889, 183506688, 226498560, 2635143425, 2627803649, 204479232,
	2680232961, 256908544, 249568768, 2658213633, 2181111809, 311435520,
	320872960, 2209424129, 272638976, 2161190145, 2170627585, 300951296,
	377497600, 2249271553, 2275486209, 389032704, 2227252225, 340798720,
	367013376, 2238787329, 452997120, 2341548289, 2317431297, 447755008,
	2302751745, 433075456, 408958464, 2297509633, 2407610369, 521156864,
	513817088, 2385591041, 499137536, 2370911489, 2363571713, 477118208,
	3019980801, 613433600, 622871040, 3048293121, 641745920, 3067168001,
	3076605441, 670058240, 545277952, 2953922817, 2980137473, 556813056,
	2999012353, 575687936, 601902592, 3010547457, 754995200, 3180417281,
	3156300289, 749753088, 3208729601, 802182400, 778065408, 3203487489,
	3112261633, 688937216, 681597440, 3090242305, 734026752, 3142671617,
	3135331841, 712007424, 905994240, 2794545409, 2803982849, 934306560,
	2755748865, 886072576, 895510016, 2784061185, 2726389761, 839936256,
	866150912, 2737924865, 817916928, 2689690881, 2715905537, 829452032,
	2936107009, 1066430720, 1042313728, 2930864897, 1027634176, 2916185345,
	2892068353, 1022392064, 998275072, 2870049025, 2862709249, 976255744,
	2848029697, 961576192, 954236416, 2826010369, 3623976961, 1217429760,
	1226867200, 3652289281, 1245742080, 3671164161, 3680601601, 1274054400,
	1283491840, 3692136705, 3718351361, 1295026944, 3737226241, 1313901824,
	1340116480, 3748761345, 1090555904, 3515977985, 3491860993, 1085313792,
	3544290305, 1137743104, 1113626112, 3539048193, 3582040065, 1158715648,
	1151375872, 3560020737, 1203805184, 3612450049, 3605110273, 1181785856,
	1509990400, 3398541569, 3407979009, 1538302720, 3359745025, 1490068736,
	1499506176, 3388057345, 3464603649, 1578150144, 1604364800, 3476138753,
	1556130816, 3427904769, 3454119425, 1567665920, 3271667713, 1401991424,
	1377874432, 3266425601, 1363194880, 3251746049, 3227629057, 1357952768,
	1468053504, 3339827457, 3332487681, 1446034176, 3317808129, 1431354624,
	1424014848, 3295788801, 1811988480, 4237410561, 4246848001, 1840300800,
	4265722881, 1859175680, 1868613120, 4294035201, 4169254913, 1745930496,
	1772145152, 4180790017, 1791020032, 4199664897, 4225879553, 1802555136,
	4110536705, 1703989504, 1679872512, 4105294593, 1732301824, 4157723905,
	4133606913, 1727059712, 1635833856, 4044478721, 4037138945, 1613814528,
	4089568257, 1666243840, 1658904064, 4067548929, 3993100289, 2123424000,
	2132861440, 4021412609, 2084627456, 3973178625, 3982616065, 2112939776,
	2055268352, 3927042305, 3953256961, 2066803456, 3905022977, 2018569472,
	2044784128, 3916558081, 1996550144, 3885101313, 3860984321, 1991308032,
	3846304769, 1976628480, 1952511488, 3841062657, 3816945665, 1930492160,
	1923152384, 3794926337, 1908472832, 3780246785, 3772907009, 1886453504};

@implementation ECMEncoder {
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
		//This code was originally used to generate edc_lut, ecc_b_lut, and ecc_f_lut.
//		uint32_t i, j, edc;
//		for(i = 0; i < 256; i++) {
//			j = (i << 1) ^ (i & 0x80 ? 0x11D : 0);
//			ecc_f_lut[i] = j;
//			ecc_b_lut[i ^ j] = i;
//			edc = i;
//			for (j = 0; j < 8; j++) {
//				edc = (edc >> 1) ^ (edc & 1 ? 0xD8018001 : 0);
//			}
//			edc_lut[i] = edc;
//		}
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
	while (size--) {
		edc = (edc >> 8) ^ edc_lut[(edc ^ (*src++)) & 0xFF];
	}
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
	for (major = 0; major < major_count; major++) {
		uint32_t index = (major >> 1) * major_mult + (major & 1);
		uint8_t ecc_a = 0;
		uint8_t ecc_b = 0;
		for (minor = 0; minor < minor_count; minor++) {
			uint8_t temp = src[index];
			index += minor_inc;
			if(index >= size) index -= size;
			ecc_a ^= temp;
			ecc_b ^= temp;
			ecc_a = ecc_f_lut[ecc_a];
		}
		ecc_a = ecc_b_lut[ecc_f_lut[ecc_a] ^ ecc_b];
		if(dest[major              ] != (ecc_a        )) {
			return NO;
		}
		if(dest[major + major_count] != (ecc_a ^ ecc_b)) {
			return NO;
		}
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
	uint8_t address[4];
	/* Save the address and zero it out */
	if (zeroaddress) {
		for (int i = 0; i < 4; i++) {
			address[i] = sector[12 + i];
			sector[12 + i] = 0;
		}
	}
	/* Compute ECC P code */
	if (!([self computeECCBlockWithSource:sector + 0xC majorCount:86 minorCount:24 majorMult:2 minorIncrement:86 destination:dest + 0x81C - 0x81C])) {
		if (zeroaddress) {
			for (int i = 0; i < 4; i++) {
				sector[12 + i] = address[i];
			}
		}
		return NO;
	}
	/* Compute ECC Q code */
	r = [self computeECCBlockWithSource:sector + 0xC majorCount:52 minorCount:43 majorMult:86 minorIncrement:88 destination:dest + 0x8C8 - 0x81C];
	/* Restore the address */
	if (zeroaddress) {
		for (int i = 0; i < 4; i++) {
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
	if ((sector[0x0] != sector[0x4]) ||
		(sector[0x1] != sector[0x5]) ||
		(sector[0x2] != sector[0x6]) ||
		(sector[0x3] != sector[0x7])) {
		canbetype2 = NO;
		canbetype3 = NO;
		if (!canbetype1) {
			return 0;
		}
	}
	
	/* Check EDC */
	myedc = [self computeEDCBlock:0 withSource:sector size:0x808];
	if (canbetype2) {
		if ((sector[0x808] != ((myedc >>  0) & 0xFF)) ||
			(sector[0x809] != ((myedc >>  8) & 0xFF)) ||
			(sector[0x80A] != ((myedc >> 16) & 0xFF)) ||
			(sector[0x80B] != ((myedc >> 24) & 0xFF))) {
			canbetype2 = NO;
		}
	}
	myedc = [self computeEDCBlock:myedc withSource:sector +0x808 size:8];
	if (canbetype1) {
		if ((sector[0x810] != ((myedc >>  0) & 0xFF)) ||
			(sector[0x811] != ((myedc >>  8) & 0xFF)) ||
			(sector[0x812] != ((myedc >> 16) & 0xFF)) ||
			(sector[0x813] != ((myedc >> 24) & 0xFF))) {
			canbetype1 = NO;
		}
	}
	myedc = [self computeEDCBlock:myedc withSource:sector + 0x810 size:0x10C];
	if (canbetype3) {
		if ((sector[0x91C] != ((myedc >>  0) & 0xFF)) ||
			(sector[0x91D] != ((myedc >>  8) & 0xFF)) ||
			(sector[0x91E] != ((myedc >> 16) & 0xFF)) ||
			(sector[0x91F] != ((myedc >> 24) & 0xFF))) {
			canbetype3 = NO;
		}
	}
	/* Check ECC */
	if (canbetype1) {
		if (!([self generateECCWithSector:sector zeroAddress:0 destination:sector + 0x81C])) {
			canbetype1 = NO;
		}
	}
	if (canbetype2) {
		if (!([self generateECCWithSector:sector - 0x10 zeroAddress:1 destination:sector + 0x80C])) {
			canbetype2 = NO;
		}
	}
	if(canbetype1) {
		return 1;
	}
	if(canbetype2) {
		return 2;
	}
	if(canbetype3) {
		return 3;
	}
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
			if (b > 2352) {
				b = 2352;
			}
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
