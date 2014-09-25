#import <Foundation/Foundation.h>

OBJC_EXPORT int CDRRunSpecs();
OBJC_EXPORT void CDRInjectCedarIntoSenTestSuiteOrXCTestSuite();
OBJC_EXPORT NSArray *CDRReportersFromEnv(const char *defaultReporterClassName);

OBJC_EXPORT int runSpecs() __attribute__((deprecated("Please use CDRRunSpecs()")));
OBJC_EXPORT int runAllSpecs() __attribute__((deprecated("Please use CDRRunSpecs()")));
OBJC_EXPORT int runSpecsWithCustomExampleReporters(NSArray *reporters) __attribute__((deprecated("Please use CDRRunSpecsWithCustomExampleReporters()")));
