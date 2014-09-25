#import "CDROTestRunner.h"
#import "CDROTestHelper.h"
#import "CDRFunctions.h"
#import "CDRRuntimeUtilities.h"

@interface CDROTestRunner ()
@property (nonatomic) int exitStatus;
@end

@implementation CDROTestRunner

+ (void)load {
    CDRInjectCedarIntoSenTestSuiteOrXCTestSuite();
}

@end
