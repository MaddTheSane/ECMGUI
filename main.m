#import <mach-o/dyld.h>

extern int NSApplicationMain(int argc, const char *argv[]);
extern void ASKInitialize();

int main(int argc, const char *argv[])
{
#if 0
	if (NSIsSymbolNameDefined("_ASKInitialize"))
	{
		NSSymbol *symbol = NSLookupAndBindSymbol("_ASKInitialize");
		if (symbol)
		{
			void (*initializeASKFunc)(void) = NSAddressOfSymbol(symbol);
			if (initializeASKFunc)
			{
				initializeASKFunc();
			}
		}
	}
#else
	ASKInitialize();
#endif
	
    return NSApplicationMain(argc, argv);
}
