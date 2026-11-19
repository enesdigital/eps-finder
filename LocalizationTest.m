#import <Foundation/Foundation.h>
#import "Render.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSCAssert(argc >= 5, @"Pass language, expected caption, expected error and production app path");
        NSString *language = @(argv[1]);
        NSString *caption = @(argv[2]);
        NSString *description = @(argv[3]);
        NSCAssert([NSBundle.mainBundle.preferredLocalizations.firstObject isEqual:language],
                  @"Wrong automatic language: %@", NSBundle.mainBundle.preferredLocalizations);
        NSCAssert([NSLocalizedString(@"app.showSample", nil) isEqual:caption], @"Wrong localized button");
        NSError *error = nil;
        EPSRenderPDF([NSURL URLWithString:@"https://invalid.example/sample.eps"], 1, &error);
        NSCAssert([error.localizedDescription isEqual:description], @"Wrong localized error: %@", error);
        NSURL *app = [NSURL fileURLWithPath:@(argv[4])];
        NSArray *urls = @[app, [app URLByAppendingPathComponent:@"Contents/PlugIns/Preview.appex"],
                          [app URLByAppendingPathComponent:@"Contents/PlugIns/Thumbnail.appex"]];
        for (NSURL *url in urls) {
            NSBundle *bundle = [NSBundle bundleWithURL:url];
            NSCAssert([bundle.preferredLocalizations.firstObject isEqual:language], @"Wrong bundle language: %@", url);
            NSCAssert([[bundle localizedStringForKey:@"app.showSample" value:nil table:nil] isEqual:caption],
                      @"Wrong bundle translation: %@", url);
        }
        for (NSUInteger index = 1; index < urls.count; index++) {
            NSBundle *bundle = [NSBundle bundleWithURL:urls[index]];
            NSString *key = index == 1 ? @"extension.preview.name" : @"extension.thumbnail.name";
            NSCAssert([[bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"] isEqual:NSLocalizedString(key, nil)],
                      @"Wrong localized extension name");
        }
        printf("PASS: native language %s, app/extension strings, translated error, extension names\n", language.UTF8String);
    }
    return 0;
}
