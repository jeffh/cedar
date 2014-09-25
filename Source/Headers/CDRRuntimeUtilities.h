#import <Foundation/Foundation.h>

OBJC_EXPORT void CDRCopyClassInternalsFromClass(Class sourceClass, Class destinationClass);
OBJC_EXPORT void CDRCopyClassMethodsFromClass(Class sourceClass, Class destinationClass);

OBJC_EXPORT NSString *CDRGetTestBundleExtension();
OBJC_EXPORT NSArray *CDRShuffleItemsInArrayWithSeed(NSArray *sortedItems, unsigned int seed);
OBJC_EXPORT Class CDRGetFirstClassThatExists(NSArray *classNames);
