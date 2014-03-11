#import <Foundation/Foundation.h>
#import "CDRExampleBase.h"

@interface CDRExampleStateMap : NSObject {
    NSDictionary *stateMap_;
}

+ (id)stateMap;

- (NSString *)descriptionForState:(CDRExampleState)state;

@end
