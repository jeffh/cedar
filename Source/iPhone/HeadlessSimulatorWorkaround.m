#import "HeadlessSimulatorWorkaround.h"
#import <objc/runtime.h>

void CDRSimulatorWorkaround_CreateFakePurpleWorkspacePort() {
    CFMessagePortRef remotePort = CFMessagePortCreateRemote(NULL, (CFStringRef)@"PurpleWorkspacePort");
    if (remotePort == NULL) {
        NSLog(@"No workspace port detected, creating one and disabling -[UIWindow _createContext]...");
        static CFMessagePortRef localPort;
        localPort = CFMessagePortCreateLocal(NULL, (CFStringRef)@"PurpleWorkspacePort", NULL, NULL, NULL);
        SEL _createContextSelector = NSSelectorFromString(@"_createContext");
        class_replaceMethod([UIWindow class], _createContextSelector, imp_implementationWithBlock(^{}), "v@:");
    } else {
        CFRelease(remotePort);
    }
}

void CDRSimulatorWorkaround_HideBKSetAccelerometerClientEventsEnabled() {
    SEL _serverWasRestartedSelector = NSSelectorFromString(@"_serverWasRestarted");
    // Found out via `sudo dtruss -p PID -s`
    class_replaceMethod(
        NSClassFromString(@"BKSAccelerometer"),
        _serverWasRestartedSelector,
        imp_implementationWithBlock(^{}),
        "v@:"
    );
}

void setUpFakeWorkspaceIfRequired() {
#if TARGET_IPHONE_SIMULATOR
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSInteger majorVersion = [[[systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] integerValue];

    if (majorVersion >= 6) {
        CDRSimulatorWorkaround_CreateFakePurpleWorkspacePort();
        CDRSimulatorWorkaround_HideBKSetAccelerometerClientEventsEnabled();
    }
    [pool drain];
#endif
}
