#import <Cedar/Cedar.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(CedarXCTestSupportSpec)

describe(@"NSObject", ^{
    it(@"should be running tests", ^{
        1 should equal(1);
    });
});

SPEC_END
