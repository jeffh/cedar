#import "CDROTestRunner.h"
#import "CDROTestHelper.h"
#import "CDRFunctions.h"

@interface CDROTestRunner ()
@property (nonatomic) int exitStatus;
@end

@implementation CDROTestRunner

+ (void)load {
    if (!CDRGetTestBundleExtension()) {
        return; // we're not in a test bundle
    }
   CDRInjectIntoXCTestRunner();
}

@end
