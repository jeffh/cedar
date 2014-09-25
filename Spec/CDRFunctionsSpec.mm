#if TARGET_OS_IPHONE
// Normally you would include this file out of the framework.  However, we're
// testing the framework here, so including the file from the framework will
// conflict with the compiler attempting to include the file from the project.
#import "Cedar-iOS.h"
#else
#import <Cedar/Cedar.h>
#endif

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(CDRFunctionsSpec)

describe(@"CDRFunctions", ^{
    describe(@"running a test bundle without linking against XCTest or SenTestingKit", ^{
        it(@"should raise an exception", ^{
            ^{ CDRInjectIntoXCTestRunner(); } should raise_exception().with_name(@"CedarNoTestFrameworkAvailable");
        });
    });
});

SPEC_END
