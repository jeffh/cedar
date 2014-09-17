#import "CDROTestRunner.h"
#import "CDROTestHelper.h"
#import "CDRFunctions.h"
#import <objc/runtime.h>
#import "CDRRuntimeUtilities.h"
#import "CDRXTestSuite.h"

@interface CDRXCTestSupport : NSObject
- (id)testSuiteWithName:(NSString *)name;
- (id)defaultTestSuite;
- (id)testSuiteForBundlePath:(NSString *)bundlePath;
- (id)testSuiteForTestCaseWithName:(NSString *)name;
- (id)testSuiteForTestCaseClass:(Class)testCaseClass;
- (id)initWithName:(NSString *)aName;

- (id)CDR_original_defaultTestSuite;

- (void)addTest:(id)test;

- (id)initWithInvocation:(NSInvocation *)invocation;
@end

#import "CDRReportDispatcher.h"
#import "CDRSpec.h"
extern void CDRDefineSharedExampleGroups();
extern void CDRDefineGlobalBeforeAndAfterEachBlocks();
extern NSArray *CDRReportersFromEnv(const char *defaultReporterClassName);
extern unsigned int CDRGetRandomSeed();
extern NSArray *CDRSpecClassesToRun();
extern NSArray *CDRPermuteSpecClassesWithSeed(NSArray *unsortedSpecClasses, unsigned int seed);
extern NSArray *CDRSpecsFromSpecClasses(NSArray *specClasses);
extern void CDRMarkFocusedExamplesInSpecs(NSArray *specs);
extern void CDRMarkXcodeFocusedExamplesInSpecs(NSArray *specs, NSArray *arguments);
extern NSArray *CDRRootGroupsFromSpecs(NSArray *specs);

static id CDRCreateXCTestSuite() {
    Class testSuiteClass = NSClassFromString(@"XCTestSuite") ?: NSClassFromString(@"SenTestSuite");
    Class testSuiteSubclass = NSClassFromString(@"_CDRXTestSuite");

    if (testSuiteSubclass == nil) {
        size_t size = class_getInstanceSize([CDRXTestSuite class]) - class_getInstanceSize([NSObject class]);
        testSuiteSubclass = objc_allocateClassPair(testSuiteClass, "_CDRXTestSuite", size);
        CDRCopyClassInternalsFromClass([CDRXTestSuite class], testSuiteSubclass);
        objc_registerClassPair(testSuiteClass);
    }

    id testSuite = [[(id)testSuiteSubclass alloc] initWithName:@"Cedar"];
    CDRDefineSharedExampleGroups();
    CDRDefineGlobalBeforeAndAfterEachBlocks();

    unsigned int seed = CDRGetRandomSeed();

    NSArray *specClasses = CDRSpecClassesToRun();
    NSArray *permutedSpecClasses = CDRPermuteSpecClassesWithSeed(specClasses, seed);
    NSArray *specs = CDRSpecsFromSpecClasses(permutedSpecClasses);
    CDRMarkFocusedExamplesInSpecs(specs);
    CDRMarkXcodeFocusedExamplesInSpecs(specs, [[NSProcessInfo processInfo] arguments]);

    CDRReportDispatcher *dispatcher = [[[CDRReportDispatcher alloc] initWithReporters:CDRReportersToRun()] autorelease];

    [CDRXTestSuite setDispatcher:dispatcher];

    NSArray *groups = CDRRootGroupsFromSpecs(specs);
    [dispatcher runWillStartWithGroups:groups andRandomSeed:seed];

    for (CDRSpec *spec in specs) {
        [testSuite addTest:[spec testSuiteWithRandomSeed:seed dispatcher:dispatcher]];
    }
    return testSuite;
}

static void CDRInjectIntoXCTestRunner() {
    Class testSuiteClass = NSClassFromString(@"XCTestSuite") ?: NSClassFromString(@"SenTestSuite");
    Class testSuiteMetaClass = object_getClass(testSuiteClass);
    Method m = class_getClassMethod(testSuiteClass, @selector(defaultTestSuite));
    class_addMethod(testSuiteMetaClass, @selector(CDR_original_defaultTestSuite), method_getImplementation(m), method_getTypeEncoding(m));
    IMP newImp = imp_implementationWithBlock(^id(id self){
        id defaultSuite = [self CDR_original_defaultTestSuite];
        [defaultSuite addTest:CDRCreateXCTestSuite()];
        return defaultSuite;
    });
    class_replaceMethod(testSuiteMetaClass, @selector(defaultTestSuite), newImp, method_getTypeEncoding(m));
}



@interface CDROTestRunner ()
@property (nonatomic) int exitStatus;
@end

@implementation CDROTestRunner

void CDRRunTests(id self, SEL _cmd, id object) {
    CDROTestRunner *runner = [[CDROTestRunner alloc] init];
    [runner runAllTestsWithTestProbe:self];
}

+ (void)load {
//    CDRHijackOCUnitAndXCTestRun((IMP)CDRRunTests);
    CDRInjectIntoXCTestRunner();
}

- (void)runAllTestsWithTestProbe:(id)testProbe {
    [self runStandardTestsWithTestProbe:testProbe];
    [self runSpecs];

    // otest always returns 0 as its exit code even if any test fails;
    // we need to forcibly exit with correct exit code to make CI happy.
    [self exitWithAggregateStatus];
}

- (void)runStandardTestsWithTestProbe:(id)testProbe {
    int exitStatus = 0;
    if (CDRIsXCTest()) {
        exitStatus = CDRRunXCUnitTests(testProbe);
    } else {
        exitStatus = CDRRunOCUnitTests(testProbe);
    }
    [self recordExitStatus:exitStatus];
}

- (void)runSpecs {
    int exitStatus = CDRRunSpecs();
    [self recordExitStatus:exitStatus];
}

- (void)recordExitStatus:(int)status {
    self.exitStatus |= status;
}

- (void)exitWithAggregateStatus {
    [self exitWithStatus:self.exitStatus];
}

- (void)exitWithStatus:(int)status {
    fflush(stdout);
    fflush(stderr);
    fclose(stdout);
    fclose(stderr);

    exit(status);
}

@end
