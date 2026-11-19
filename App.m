#import <AppKit/AppKit.h>

@interface EPSAppDelegate : NSObject <NSApplicationDelegate>
@end
@implementation EPSAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
        [NSApp activateIgnoringOtherApps:YES];
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"EPS Finder";
        alert.informativeText = NSLocalizedString(@"app.instructions", nil);
        [alert addButtonWithTitle:NSLocalizedString(@"app.showSample", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"common.ok", nil)];
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            NSURL *sample = [NSBundle.mainBundle URLForResource:@"EPS-Test" withExtension:@"eps"];
            if (sample) [NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:@[sample]];
        }
        [NSApp terminate:nil];
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        EPSAppDelegate *delegate = [EPSAppDelegate new];
        application.delegate = delegate;
        [application setActivationPolicy:NSApplicationActivationPolicyRegular];
        [application run];
    }
    return 0;
}
