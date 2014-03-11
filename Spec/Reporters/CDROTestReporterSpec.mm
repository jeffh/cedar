#if TARGET_OS_IPHONE
// Normally you would include this file out of the framework.  However, we're
// testing the framework here, so including the file from the framework will
// conflict with the compiler attempting to include the file from the project.
#import "SpecHelper.h"
#else
#import <Cedar/SpecHelper.h>
#endif

#import "CDROTestReporter.h"
#import "CDRExampleGroup.h"
#import "CDRExample.h"
#import "CDRReportDispatcher.h"
#import <objc/runtime.h>


@interface TestCDROTestReporter : CDROTestReporter

@property (strong, nonatomic) NSMutableString *reporterOutput;

- (void)logMessage:(NSString *)message;

@end

@implementation TestCDROTestReporter

- (void)logMessage:(NSString *)message {
    [self.reporterOutput appendFormat:@"%@\n", message];
}

@end

@interface MyExampleSpec : CDRSpec
@end

@implementation MyExampleSpec
- (void)declareBehaviors {}
@end

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(CDROTestReporterSpec)

describe(@"CDROTestReporter", ^{
    __block TestCDROTestReporter *reporter;
    __block CDRSpec *spec1, *spec2;
    __block CDRExampleGroup *group1, *group2, *focusedGroup;
    __block CDRExample *passingExample, *failingExample, *focusedExample;
    __block NSString *bundleName;
    __block CDRReportDispatcher *dispatcher;

    beforeEach(^{
        bundleName = [NSBundle mainBundle].bundleURL.pathComponents.lastObject;

        reporter = [[[TestCDROTestReporter alloc] init] autorelease];
        reporter.reporterOutput = [NSMutableString string];
        dispatcher = [[[CDRReportDispatcher alloc] initWithReporters:@[reporter]] autorelease];

        spec1 = [[[CDRSpec alloc] init] autorelease];
        spec2 = [[[MyExampleSpec alloc] init] autorelease];
        group1 = [CDRExampleGroup groupWithText:@"my group"];
        group1.spec = spec1;
        group2 = [CDRExampleGroup groupWithText:@"my group other"];
        group2.spec = spec2;
        passingExample = [CDRExample exampleWithText:@"passing" andBlock:^{}];
        passingExample.spec = spec1;
        failingExample = [CDRExample exampleWithText:@"failing" andBlock:^{fail(@"whale");}];
        failingExample.spec = spec1;

        focusedGroup = [CDRExampleGroup groupWithText:@"laser"];
        focusedExample = [CDRExample exampleWithText:@"focus" andBlock:^{}];
        focusedGroup.focused = YES;
        [focusedGroup add:focusedExample];
        focusedGroup.spec = spec1;
    });

    afterEach(^{
        reporter.reporterOutput = nil;
    });

    describe(@"starting the test run", ^{
        context(@"when not focused", ^{
            beforeEach(^{
                [dispatcher runWillStartWithGroups:@[group1] andRandomSeed:1337];
            });

            it(@"should report the random seed", ^{
                reporter.reporterOutput should contain(@"Cedar Random Seed: 1337");
            });

            it(@"should report that all tests are running", ^{
                reporter.reporterOutput should contain(@"Test Suite 'All tests' started at");
            });

            it(@"should report the test bundle suite", ^{
                reporter.reporterOutput should contain([NSString stringWithFormat:@"Test Suite '%@' started at", bundleName]);
            });
        });

        context(@"when focused", ^{
            __block BOOL originalState;

            beforeEach(^{
                originalState = [SpecHelper specHelper].shouldOnlyRunFocused;
                [SpecHelper specHelper].shouldOnlyRunFocused = YES;

                [dispatcher runWillStartWithGroups:@[focusedGroup] andRandomSeed:34];
            });

            afterEach(^{
                [SpecHelper specHelper].shouldOnlyRunFocused = originalState;
            });

            it(@"should report the random seed", ^{
                reporter.reporterOutput should contain(@"Cedar Random Seed: 34");
            });

            it(@"should report that a subset of tests are running", ^{
                reporter.reporterOutput should contain(@"Test Suite 'Multiple Selected Tests' started at");
            });

            it(@"should report the test bundle suite", ^{
                reporter.reporterOutput should contain([NSString stringWithFormat:@"Test Suite '%@' started at", bundleName]);
            });
        });
    });

    describe(@"finishing the run", ^{
        context(@"when not focused", ^{
            beforeEach(^{
                [dispatcher runWillStartWithGroups:@[group1] andRandomSeed:1337];
                reporter.reporterOutput = [NSMutableString string];
                [dispatcher runDidComplete];
            });

            it(@"should report the end of all the tests", ^{
                reporter.reporterOutput should contain(@"Test Suite 'All tests' finished at");
            });

            it(@"should report the test bundle suite stats", ^{
                reporter.reporterOutput should contain([NSString stringWithFormat:@"Test Suite '%@' finished at", bundleName]);
            });
        });

        context(@"when focused", ^{
            __block BOOL originalState;
            beforeEach(^{
                originalState = [SpecHelper specHelper].shouldOnlyRunFocused;
                [SpecHelper specHelper].shouldOnlyRunFocused = YES;

                [dispatcher runWillStartWithGroups:@[focusedGroup] andRandomSeed:42];
                reporter.reporterOutput = [NSMutableString string];
                [dispatcher runDidComplete];
            });

            afterEach(^{
                [SpecHelper specHelper].shouldOnlyRunFocused = originalState;
            });

            it(@"should report the end of all the tests", ^{
                reporter.reporterOutput should contain(@"Test Suite 'Multiple Selected Tests' finished at");
            });

            it(@"should report the test bundle suite stats", ^{
                reporter.reporterOutput should contain([NSString stringWithFormat:@"Test Suite '%@' finished at", bundleName]);
            });

        });
    });

    describe(@"processing an example", ^{
        beforeEach(^{
            [group1 add:passingExample];
            [group1 add:failingExample];
            [spec1.rootGroup add:group1];
            [dispatcher runWillStartWithGroups:@[spec1.rootGroup] andRandomSeed:1337];
            reporter.reporterOutput = [NSMutableString string];

            [group1 runWithDispatcher:dispatcher];
        });

        it(@"should report the spec class", ^{
            reporter.reporterOutput should contain(@"Test Suite 'CDRSpec' started at");
        });

        it(@"should report the spec class finishing after the run completes", ^{
            [dispatcher runDidComplete];

            reporter.reporterOutput should contain(@"Test Suite 'CDRSpec' finished at");
            reporter.reporterOutput should contain(@"Executed 2 tests, with 1 failure (0 unexpected) in");
        });

        it(@"should report the passing example", ^{
            reporter.reporterOutput should contain(@"Test Case '-[CDRSpec my_group_passing]' started.");
        });

        it(@"should finish the passing example", ^{
            reporter.reporterOutput should contain(@"Test Case '-[CDRSpec my_group_passing]' passed (");
        });

        it(@"should report the passing example", ^{
            reporter.reporterOutput should contain(@"Test Case '-[CDRSpec my_group_failing]' started.");
        });

        it(@"should finish the passing example", ^{
            reporter.reporterOutput should contain(@"Test Case '-[CDRSpec my_group_failing]' failed (");
        });
    });

    describe(@"processing multiple spec classes", ^{
        beforeEach(^{
            [group1 add:passingExample];
            CDRExampleGroup *anotherPassing = [CDRExample exampleWithText:@"another_passing" andBlock:^{}];
            anotherPassing.spec = spec1;
            [group1 add:anotherPassing];
            [spec1.rootGroup add:group1];

            [group2 add:failingExample];
            group2.spec = spec2;
            failingExample.spec = spec2;

            CDRExample *pendingExample = [CDRExample exampleWithText:@"pending" andBlock:nil];
            pendingExample.spec = spec2;
            [group2 add:pendingExample];
            [spec2.rootGroup add:group2];

            [dispatcher runWillStartWithGroups:@[spec1.rootGroup, spec2.rootGroup] andRandomSeed:1337];
            reporter.reporterOutput = [NSMutableString string];

            [group1 runWithDispatcher:dispatcher];
            [group2 runWithDispatcher:dispatcher];
        });

        it(@"should report the spec class", ^{
            reporter.reporterOutput should contain(@"Test Suite 'CDRSpec' started at");
        });

        it(@"should report the passing example", ^{
            reporter.reporterOutput should contain(@"Test Case '-[CDRSpec my_group_passing]' started.");
        });

        it(@"should finish the passing example", ^{
            reporter.reporterOutput should contain(@"Test Case '-[CDRSpec my_group_passing]' passed");
        });

        it(@"should report the spec class finishing after the run completes", ^{
            [dispatcher runDidComplete];

            reporter.reporterOutput should contain(@"Test Suite 'CDRSpec' finished at");

            NSRange range = [reporter.reporterOutput rangeOfString:@"Test Suite 'CDRSpec' finished at"];
            [reporter.reporterOutput substringFromIndex:range.location] should contain(@"Executed 3 tests, with 1 failure (0 unexpected) in");
        });

        it(@"should report the failing example", ^{
            reporter.reporterOutput should contain(@"Test Case '-[MyExampleSpec my_group_other_failing]' started.");
        });

        it(@"should report the failing example's error", ^{
            reporter.reporterOutput should contain(@": error: -[MyExampleSpec my_group_other_failing] :");
        });

        it(@"should finish the failing example", ^{
            reporter.reporterOutput should contain(@"Test Case '-[MyExampleSpec my_group_other_failing]' failed");
        });

        it(@"should not report the pending example", ^{
            reporter.reporterOutput should_not contain(@"Test Case '-[MyExampleSpec my_group_other_pending]'");
        });
    });
});

SPEC_END
