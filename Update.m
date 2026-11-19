#import "Update.h"

static NSArray<NSString *> *EPSVersion(id value) {
    if (![value isKindOfClass:NSString.class]) return nil;
    NSString *version = [value hasPrefix:@"v"] ? [value substringFromIndex:1] : value;
    NSString *component = @"(0|[1-9][0-9]{0,8})";
    NSString *pattern = [NSString stringWithFormat:@"^%@\\.%@\\.%@\\z", component, component, component];
    if ([version rangeOfString:pattern options:NSRegularExpressionSearch].location == NSNotFound) return nil;
    return [version componentsSeparatedByString:@"."];
}

BOOL EPSIsNewerVersion(NSString *candidate, NSString *installed) {
    NSArray *remote = EPSVersion(candidate), *local = EPSVersion(installed);
    // The first release used the two-component version 1.0.
    if (!local && [installed isKindOfClass:NSString.class]) local = EPSVersion([installed stringByAppendingString:@".0"]);
    if (!remote || !local) return NO;
    for (NSUInteger index = 0; index < 3; index++) {
        NSInteger a = [remote[index] integerValue], b = [local[index] integerValue];
        if (a != b) return a > b;
    }
    return NO;
}
