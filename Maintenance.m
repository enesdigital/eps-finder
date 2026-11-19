#import "Maintenance.h"
#import "Update.h"
#import <ServiceManagement/ServiceManagement.h>

NSArray<NSURL *> *EPSOlderCopies(NSArray<NSURL *> *directories, NSURL *installedApp) {
    NSDictionary *current = [NSDictionary dictionaryWithContentsOfURL:[installedApp URLByAppendingPathComponent:@"Contents/Info.plist"]];
    NSMutableArray *older = [NSMutableArray new];
    for (NSURL *directory in directories) {
        for (NSURL *candidate in [NSFileManager.defaultManager contentsOfDirectoryAtURL:directory
                     includingPropertiesForKeys:@[NSURLIsSymbolicLinkKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil]) {
            if (![candidate.pathExtension isEqual:@"app"] || [candidate.URLByStandardizingPath isEqual:installedApp.URLByStandardizingPath]) continue;
            NSNumber *symlink = nil;
            if (![candidate getResourceValue:&symlink forKey:NSURLIsSymbolicLinkKey error:nil] || symlink.boolValue) continue;
            NSDictionary *info = [NSDictionary dictionaryWithContentsOfURL:[candidate URLByAppendingPathComponent:@"Contents/Info.plist"]];
            if ([info[@"CFBundleIdentifier"] isEqual:@"local.epsfinder"] &&
                EPSIsNewerVersion(current[@"CFBundleShortVersionString"], info[@"CFBundleShortVersionString"])) [older addObject:candidate];
        }
    }
    return older;
}

BOOL EPSRetireOlderCopies(NSURL *installedApp, NSError **error) {
    NSArray *directories = @[[NSURL fileURLWithPath:@"/Applications" isDirectory:YES],
                             [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Applications"] isDirectory:YES]];
    BOOL success = YES;
    for (NSURL *old in EPSOlderCopies(directories, installedApp)) {
        NSError *failure = nil;
        if (![NSFileManager.defaultManager trashItemAtURL:old resultingItemURL:nil error:&failure]) {
            success = NO;
            if (error) *error = failure;
        }
    }
    return success;
}

BOOL EPSConfigureLogin(NSError **error) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    SMAppService *service = SMAppService.mainAppService;
    if ([defaults boolForKey:@"LoginItemConfigured"] && service.status != SMAppServiceStatusNotFound) return YES;
    if (service.status == SMAppServiceStatusEnabled || service.status == SMAppServiceStatusRequiresApproval ||
        [service registerAndReturnError:error]) {
        [defaults setBool:YES forKey:@"LoginItemConfigured"];
        return YES;
    }
    return NO;
}
