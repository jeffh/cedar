#import "CDRExampleStateMap.h"

static CDRExampleStateMap *sharedInstance__;

@implementation CDRExampleStateMap

+ (id)stateMap {
    if (!sharedInstance__) {
        sharedInstance__ = [[CDRExampleStateMap alloc] init];
    }
    return sharedInstance__;
}

- (id)init {
    if (self = [super init]) {
        stateMap_ = [[NSDictionary alloc] initWithObjectsAndKeys:
                     @"RUNNING", [NSNumber numberWithInteger:CDRExampleStateIncomplete],
                     @"PASSED", [NSNumber numberWithInteger:CDRExampleStatePassed],
                     @"PENDING", [NSNumber numberWithInteger:CDRExampleStatePending],
                     @"SKIPPED", [NSNumber numberWithInteger:CDRExampleStateSkipped],
                     @"FAILED", [NSNumber numberWithInteger:CDRExampleStateFailed],
                     @"ERROR", [NSNumber numberWithInteger:CDRExampleStateError],
                     nil];
    }
    return self;
}

- (void)dealloc {
    [stateMap_ release];
    [super dealloc];
}

- (NSString *)descriptionForState:(CDRExampleState)state {
    return [stateMap_ objectForKey:[NSNumber numberWithInteger:state]];
}


@end
