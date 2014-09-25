#import "CDRRuntimeUtilities.h"
#import "CDRExampleReporter.h"
#import <objc/runtime.h>

#pragma mark - Class Mixins

static void CDRCopyProtocolsFromClass(Class sourceClass, Class destinationClass) {
    unsigned int count = 0;
    Protocol **protocols = class_copyProtocolList(sourceClass, &count);
    for (unsigned int i = 0; i < count; i++) {
        class_addProtocol(destinationClass, protocols[i]);
    }
    free(protocols);
}

static void CDRCopyInstanceMethodsFromClass(Class sourceClass, Class destinationClass) {
    unsigned int count = 0;
    Method *instanceMethods = class_copyMethodList(sourceClass, &count);
    for (unsigned int i = 0; i < count; i++) {
        Method m = instanceMethods[i];
        BOOL wasAdded = class_addMethod(destinationClass,
                                        method_getName(m),
                                        method_getImplementation(m),
                                        method_getTypeEncoding(m));
        if (!wasAdded) {
            class_replaceMethod(destinationClass,
                                method_getName(m),
                                method_getImplementation(m),
                                method_getTypeEncoding(m));
        }
    }
    free(instanceMethods);
}

static void CDRCopyInstanceVariablesFromClass(Class sourceClass, Class destinationClass) {
    unsigned int count = 0;
    Ivar *instanceVars = class_copyIvarList(sourceClass, &count);
    for (unsigned int i = 0; i < count; i++) {
        Ivar v = instanceVars[i];
        NSUInteger size = 0, align = 0;
        NSGetSizeAndAlignment(ivar_getTypeEncoding(v), &size, &align);
        class_addIvar(destinationClass,
                      ivar_getName(v),
                      size,
                      align,
                      ivar_getTypeEncoding(v));
    }
    free(instanceVars);
}

static void CDRCopyPropertiesFromClass(Class sourceClass, Class destinationClass) {
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(sourceClass, &count);
    for (unsigned int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        unsigned int attrCount = 0;
        objc_property_attribute_t *attributes = property_copyAttributeList(property, &attrCount);
        class_addProperty(destinationClass,
                          property_getName(property),
                          attributes,
                          attrCount);
        free(attributes);
    }
    free(properties);
}

void CDRCopyClassMethodsFromClass(Class sourceClass, Class destinationClass) {
    Class metaSourceClass = object_getClass(sourceClass);
    Class metaDestinationClass = object_getClass(destinationClass);
    CDRCopyInstanceMethodsFromClass(metaSourceClass, metaDestinationClass);
}

void CDRCopyClassInternalsFromClass(Class sourceClass, Class destinationClass) {
    CDRCopyProtocolsFromClass(sourceClass, destinationClass);
    CDRCopyPropertiesFromClass(sourceClass, destinationClass);
    CDRCopyInstanceVariablesFromClass(sourceClass, destinationClass);
    CDRCopyInstanceMethodsFromClass(sourceClass, destinationClass);
    CDRCopyClassMethodsFromClass(sourceClass, destinationClass);
}

Class CDRGetFirstClassThatExists(NSArray *classNames) {
    Class aClass = nil;
    for (NSString *className in classNames) {
        aClass = NSClassFromString(className);
        if (aClass) {
            break;
        }
    }
    return aClass;
}

#pragma mark - Test Bundles

NSString *CDRGetTestBundleExtension() {
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if ([arguments containsObject:@"-XCTest"]) {
        return @".xctest";
    } else if ([arguments containsObject:@"-SenTest"]) {
        return @".octest";
    }
    return nil;
}

#pragma mark - Randomization helpers

NSArray *CDRShuffleItemsInArrayWithSeed(NSArray *sortedItems, unsigned int seed) {
    NSMutableArray *shuffledItems = [sortedItems mutableCopy];
    srand(seed);

    for (int i=0; i < shuffledItems.count; i++) {
        NSUInteger idx = rand() % shuffledItems.count;
        [shuffledItems exchangeObjectAtIndex:i withObjectAtIndex:idx];
    }
    return [shuffledItems autorelease];
}

