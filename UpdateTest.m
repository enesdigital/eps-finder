#import "Update.h"
#import "Maintenance.h"
#import <CoreServices/CoreServices.h>

static NSMutableDictionary *Release(NSString *version) {
    NSString *name = [NSString stringWithFormat:@"EPS-Finder-%@-universal-unsigned.pkg", version];
    return [@{@"tag_name": [@"v" stringByAppendingString:version], @"draft": @NO, @"prerelease": @NO,
              @"html_url": [@"https://github.com/enesdigital/eps-finder/releases/tag/v" stringByAppendingString:version],
              @"assets": @[@{@"name": name, @"state": @"uploaded", @"size": @3,
                              @"digest": @"sha256:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
                              @"browser_download_url": [NSString stringWithFormat:@"https://github.com/enesdigital/eps-finder/releases/download/v%@/%@", version, name]}]} mutableCopy];
}
static NSData *JSON(id object) { return [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingFragmentsAllowed error:nil]; }
static void Rejected(id object) {
    NSError *error = nil;
    NSCAssert(!EPSAvailableUpdate(JSON(object), @"1.2.0", &error) && error, @"Unsafe release was accepted: %@", object);
}
static void SelfCheck(void) {
    NSError *error = nil;
    EPSUpdate *update = EPSAvailableUpdate(JSON(Release(@"1.10.0")), @"1.9.9", &error);
    NSCAssert([update.version isEqual:@"1.10.0"] && !error, @"Numeric version comparison failed");
    NSCAssert(EPSAvailableUpdate(JSON(Release(@"2.0.0")), @"1.99.99", &error), @"Major version comparison failed");
    NSCAssert(EPSAvailableUpdate(JSON(Release(@"1.2.1")), @"1.2.0", &error), @"Patch version comparison failed");
    NSCAssert(!EPSAvailableUpdate(JSON(Release(@"1.2.0")), @"1.2.0", &error) && !error, @"Same version offered");
    NSCAssert(!EPSAvailableUpdate(JSON(Release(@"1.2.0")), @"1.3.0", &error) && !error, @"Downgrade offered");
    for (id object in @[@[], @{}, NSNull.null, @"text"]) Rejected(object);
    NSCAssert(!EPSAvailableUpdate(nil, @"1.2.0", &error) && error, @"Missing JSON accepted");
    NSCAssert(!EPSAvailableUpdate([@"bad json" dataUsingEncoding:NSUTF8StringEncoding], @"1.2.0", &error) && error, @"Invalid JSON accepted");
    for (NSString *key in @[@"draft", @"prerelease"]) {
        NSMutableDictionary *release = Release(@"1.3.0"); release[key] = @YES; Rejected(release);
    }
    for (id version in @[@"v1.3.0-beta", @"v01.3.0", @"v1.3", @"v1.3.0\n", @"v1.999999999999.0", @"v1.3.0/../x", @"vv1.3.0", @3, NSNull.null]) {
        NSMutableDictionary *release = Release(@"1.3.0"); release[@"tag_name"] = version; Rejected(release);
    }
    for (NSString *key in @[@"html_url", @"assets", @"tag_name"]) {
        NSMutableDictionary *release = Release(@"1.3.0"); [release removeObjectForKey:key]; Rejected(release);
    }
    NSDictionary *invalid = @{
        @"browser_download_url": @[@"https://evil.example/update.pkg", @"http://github.com/update.pkg", @"https://github.com@evil.example/update.pkg", @"file:///tmp/update.pkg", NSNull.null],
        @"digest": @[@"", @"sha256:bad", @"sha256:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad\n", @{}, NSNull.null],
        @"size": @[@0, @(-1), @268435457, @3.5, @"3", NSNull.null],
        @"state": @[@"new", NSNull.null], @"name": @[@"wrong.pkg", NSNull.null]
    };
    for (NSString *key in invalid) for (id value in invalid[key]) {
        NSMutableDictionary *release = Release(@"1.3.0");
        NSMutableDictionary *asset = [release[@"assets"][0] mutableCopy]; asset[key] = value;
        release[@"assets"] = @[asset]; Rejected(release);
    }
    NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSFileManager *manager = NSFileManager.defaultManager;
    NSCAssert([manager createDirectoryAtURL:directory withIntermediateDirectories:NO attributes:nil error:&error], @"Test directory failed");
    NSURL *file = [directory URLByAppendingPathComponent:@"fixture.pkg"];
    [@"abc" writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSCAssert(EPSVerifyPackage(file, update, &error), @"Correct package rejected: %@", error);
    [@"abd" writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSCAssert(!EPSVerifyPackage(file, update, &error), @"Corrupted package accepted");
    [@"abcd" writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSCAssert(!EPSVerifyPackage(file, update, &error), @"Wrong size accepted");
    NSCAssert(!EPSVerifyPackage(directory, update, &error), @"Directory accepted");
    NSURL *link = [directory URLByAppendingPathComponent:@"link.pkg"];
    [manager createSymbolicLinkAtURL:link withDestinationURL:file error:nil];
    NSCAssert(!EPSVerifyPackage(link, update, &error), @"Symbolic link accepted");
    NSURL *apps = [directory URLByAppendingPathComponent:@"Applications"];
    NSArray *fixtures = @[@[@"Current.app", @"local.epsfinder", @"1.3.0"], @[@"Old.app", @"local.epsfinder", @"1.0.0"],
                         @[@"Equal.app", @"local.epsfinder", @"1.3.0"], @[@"Future.app", @"local.epsfinder", @"2.0.0"],
                         @[@"Unrelated.app", @"example.other", @"1.0.0"], @[@"Unknown.app", @"local.epsfinder", @"invalid"]];
    for (NSArray *fixture in fixtures) {
        NSURL *contents = [[apps URLByAppendingPathComponent:fixture[0]] URLByAppendingPathComponent:@"Contents"];
        [manager createDirectoryAtURL:contents withIntermediateDirectories:YES attributes:nil error:nil];
        [@{@"CFBundleIdentifier": fixture[1], @"CFBundleShortVersionString": fixture[2]} writeToURL:[contents URLByAppendingPathComponent:@"Info.plist"] atomically:YES];
    }
    [manager createSymbolicLinkAtURL:[apps URLByAppendingPathComponent:@"Linked.app"] withDestinationURL:[apps URLByAppendingPathComponent:@"Old.app"] error:nil];
    NSArray *copies = EPSOlderCopies(@[apps], [apps URLByAppendingPathComponent:@"Current.app"]);
    NSCAssert(copies.count == 1 && [[copies[0] lastPathComponent] isEqual:@"Old.app"], @"Unsafe old-version selection: %@", copies);
    [manager removeItemAtURL:directory error:nil];
    printf("PASS: numeric versions, no downgrade, malformed releases, trusted URLs, asset metadata, SHA256, file size/type and safe old-version selection\n");
}
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        SelfCheck();
        if (argc >= 3 && [@(argv[1]) isEqual:@"--live"]) {
            __block BOOL finished = NO;
            BOOL download = argc >= 4 && [@(argv[3]) isEqual:@"--download"];
            EPSUpdater *updater = [EPSUpdater new];
            [updater checkFromVersion:@(argv[2]) completion:^(EPSUpdate *update, NSError *error) {
                NSCAssert(!error, @"Live check failed: %@", error);
                printf("PASS: live GitHub check (%s)\n", update ? update.version.UTF8String : "current");
                if (!download) { finished = YES; return; }
                NSCAssert(update, @"Live download requires a newer published version");
                [updater download:update progress:^(double fraction) {
                    NSCAssert(fraction >= 0 && fraction <= 1, @"Invalid progress");
                } completion:^(NSURL *file, NSError *failure) {
                    NSCAssert(file && !failure, @"Live download failed: %@", failure);
                    NSError *verificationError = nil;
                    NSCAssert(EPSVerifyPackage(file, update, &verificationError), @"Saved package failed verification");
                    id quarantine = nil;
                    [file getResourceValue:&quarantine forKey:NSURLQuarantinePropertiesKey error:nil];
                    NSCAssert([quarantine isKindOfClass:NSDictionary.class] && [quarantine count] > 0, @"Download quarantine is missing");
                    [NSFileManager.defaultManager removeItemAtURL:file.URLByDeletingLastPathComponent error:nil];
                    printf("PASS: live package download, SHA256 verification and macOS quarantine\n");
                    finished = YES;
                }];
            }];
            NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:660];
            while (!finished && deadline.timeIntervalSinceNow > 0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
            [updater cancel];
            NSCAssert(finished, @"Live update timed out");
        }
    }
    return 0;
}
