#import "Update.h"
#import "Maintenance.h"

int main(void) {
    @autoreleasepool {
        NSCAssert(EPSIsNewerVersion(@"1.4.0", @"1.0"), @"Legacy version must be retired");
        NSCAssert(EPSIsNewerVersion(@"1.10.0", @"1.9.9"), @"Numeric version ordering failed");
        NSCAssert(!EPSIsNewerVersion(@"1.4.0", @"1.4.0"), @"Equal version selected");
        NSCAssert(!EPSIsNewerVersion(@"1.4.0", @"2.0.0"), @"Newer version selected");
        for (id invalid in @[@"1.0.0.0", @"1.0-beta", @"01.0.0", @"1.0.0\n", @"1.999999999999.0", NSNull.null]) {
            NSCAssert(!EPSIsNewerVersion(@"1.4.0", invalid), @"Invalid version accepted");
        }
        NSFileManager *manager = NSFileManager.defaultManager;
        NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSURL *apps = [directory URLByAppendingPathComponent:@"Applications"];
    NSArray *fixtures = @[@[@"Current.app", @"local.epsfinder", @"1.3.0"], @[@"Old.app", @"local.epsfinder", @"1.0.0"], @[@"Legacy.app", @"local.epsfinder", @"1.0"],
                         @[@"Equal.app", @"local.epsfinder", @"1.3.0"], @[@"Future.app", @"local.epsfinder", @"2.0.0"],
                         @[@"Unrelated.app", @"example.other", @"1.0.0"], @[@"Unknown.app", @"local.epsfinder", @"invalid"]];
    for (NSArray *fixture in fixtures) {
        NSURL *contents = [[apps URLByAppendingPathComponent:fixture[0]] URLByAppendingPathComponent:@"Contents"];
        [manager createDirectoryAtURL:contents withIntermediateDirectories:YES attributes:nil error:nil];
        [@{@"CFBundleIdentifier": fixture[1], @"CFBundleShortVersionString": fixture[2]} writeToURL:[contents URLByAppendingPathComponent:@"Info.plist"] atomically:YES];
    }
    [manager createSymbolicLinkAtURL:[apps URLByAppendingPathComponent:@"Linked.app"] withDestinationURL:[apps URLByAppendingPathComponent:@"Old.app"] error:nil];
    NSArray *copies = EPSOlderCopies(@[apps], [apps URLByAppendingPathComponent:@"Current.app"]);
    NSSet *expectedCopies = [NSSet setWithArray:@[@"Old.app", @"Legacy.app"]];
    NSCAssert(copies.count == 2 && [[NSSet setWithArray:[copies valueForKey:@"lastPathComponent"]] isEqual:expectedCopies], @"Unsafe old-version selection: %@", copies);
        [manager removeItemAtURL:directory error:nil];
        printf("PASS: numeric/legacy versions and safe old-copy selection\n");
    }
    return 0;
}
