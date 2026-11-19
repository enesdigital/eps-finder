#import <AppKit/AppKit.h>
#import <Sparkle/Sparkle.h>
#import "Maintenance.h"
#import <ServiceManagement/ServiceManagement.h>

@interface EPSAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property(strong) NSWindow *window;
@property(strong) NSTextField *status;
@property(strong) NSButton *checkButton;
@property(strong) SPUStandardUpdaterController *updaterController;
@property(strong) NSButton *loginButton;
@property(strong) NSTextField *loginStatus;
@property BOOL loginFailed;
@property BOOL cleanupFailed;
@end

@implementation EPSAppDelegate
- (NSString *)version { return [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]; }
- (NSButton *)button:(NSString *)key action:(SEL)action {
    return [NSButton buttonWithTitle:NSLocalizedString(key, nil) target:self action:action];
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.updaterController = [[SPUStandardUpdaterController alloc] initWithStartingUpdater:NO updaterDelegate:nil userDriverDelegate:nil];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSNumber *previous = [defaults objectForKey:@"AutomaticallyCheckForUpdates"];
    if (previous) {
        if (![defaults objectForKey:@"SUEnableAutomaticChecks"]) self.updaterController.updater.automaticallyChecksForUpdates = previous.boolValue;
        [defaults removeObjectForKey:@"AutomaticallyCheckForUpdates"];
    }
    NSMenu *menu = [NSMenu new];
    NSMenuItem *appMenu = [NSMenuItem new];
    appMenu.submenu = [NSMenu new];
    [appMenu.submenu addItemWithTitle:NSLocalizedString(@"app.quit", nil) action:@selector(terminate:) keyEquivalent:@"q"];
    [menu addItem:appMenu];
    NSApp.mainMenu = menu;
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 660, 550)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"EPS Finder";
    self.window.delegate = self;
    self.window.releasedWhenClosed = NO;
    NSTextField *title = [NSTextField labelWithString:[@"EPS Finder  " stringByAppendingString:self.version]];
    title.font = [NSFont boldSystemFontOfSize:22];
    NSTextField *instructions = [NSTextField wrappingLabelWithString:NSLocalizedString(@"app.instructions", nil)];
    NSButton *sample = [self button:@"app.showSample" action:@selector(showSample:)];
    NSButton *automatic = [NSButton checkboxWithTitle:NSLocalizedString(@"update.automatic", nil) target:nil action:NULL];
    [automatic bind:NSValueBinding toObject:self.updaterController.updater withKeyPath:@"automaticallyChecksForUpdates" options:nil];
    self.status = [NSTextField wrappingLabelWithString:NSLocalizedString(@"update.idle", nil)];
    self.status.accessibilityLabel = NSLocalizedString(@"update.status", nil);
    self.loginButton = [NSButton checkboxWithTitle:NSLocalizedString(@"startup.automatic", nil) target:self action:@selector(toggleLogin:)];
    NSButton *loginSettings = [self button:@"startup.settings" action:@selector(showLoginSettings:)];
    NSStackView *loginRow = [NSStackView stackViewWithViews:@[self.loginButton, loginSettings]];
    loginRow.spacing = 8;
    self.loginStatus = [NSTextField wrappingLabelWithString:@""];
    self.loginStatus.textColor = NSColor.secondaryLabelColor;
    self.loginStatus.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    BOOL installed = [NSBundle.mainBundle.bundlePath isEqual:@"/Applications/EPS Finder.app"];
    self.loginButton.enabled = installed;
    if (installed) {
        self.loginFailed = !EPSConfigureLogin(nil);
        self.cleanupFailed = !EPSRetireOlderCopies(NSBundle.mainBundle.bundleURL, nil);
    }
    [self refreshLoginStatus];
    self.checkButton = [NSButton buttonWithTitle:NSLocalizedString(@"update.check", nil) target:self.updaterController action:@selector(checkForUpdates:)];
    [self.checkButton bind:NSEnabledBinding toObject:self.updaterController.updater withKeyPath:@"canCheckForUpdates" options:nil];
    NSButton *releases = [self button:@"update.releases" action:@selector(showReleases:)];
    NSStackView *buttons = [NSStackView stackViewWithViews:@[self.checkButton, releases]];
    buttons.spacing = 8;
    NSBox *separator = [NSBox new];
    separator.boxType = NSBoxSeparator;
    NSStackView *stack = [NSStackView stackViewWithViews:@[title, instructions, sample, separator, loginRow, self.loginStatus, automatic, self.status, buttons]];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 16;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.window.contentView addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:self.window.contentView.leadingAnchor constant:24],
        [stack.trailingAnchor constraintEqualToAnchor:self.window.contentView.trailingAnchor constant:-24],
        [stack.topAnchor constraintEqualToAnchor:self.window.contentView.topAnchor constant:24],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:self.window.contentView.bottomAnchor constant:-24],
        [instructions.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
        [self.status.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
        [self.status.heightAnchor constraintGreaterThanOrEqualToConstant:54],
        [self.loginStatus.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
        [separator.widthAnchor constraintEqualToAnchor:stack.widthAnchor]
    ]];
    [self.window setContentSize:NSMakeSize(MAX(660, MAX(buttons.fittingSize.width, loginRow.fittingSize.width) + 48), 550)];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [self.updaterController startUpdater];
    if (self.updaterController.updater.automaticallyChecksForUpdates) [self.updaterController.updater checkForUpdatesInBackground];
}
- (void)refreshLoginStatus {
    SMAppServiceStatus state = SMAppService.mainAppService.status;
    self.loginButton.state = state == SMAppServiceStatusEnabled || state == SMAppServiceStatusRequiresApproval ? NSControlStateValueOn : NSControlStateValueOff;
    NSString *key = !self.loginButton.enabled ? @"startup.installFirst" : state == SMAppServiceStatusRequiresApproval ? @"startup.approval" :
                    self.loginFailed ? @"startup.failed" : state == SMAppServiceStatusEnabled ? @"startup.enabled" : @"startup.disabled";
    self.loginStatus.stringValue = NSLocalizedString(key, nil);
    if (self.cleanupFailed) self.loginStatus.stringValue = [self.loginStatus.stringValue stringByAppendingFormat:@"\n%@", NSLocalizedString(@"setup.cleanupFailed", nil)];
}
- (void)toggleLogin:(NSButton *)sender {
    SMAppService *service = SMAppService.mainAppService;
    BOOL enable = sender.state == NSControlStateValueOn;
    self.loginFailed = !(enable ? [service registerAndReturnError:nil] : [service unregisterAndReturnError:nil]);
    if (!self.loginFailed) [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"LoginItemConfigured"];
    [self refreshLoginStatus];
}
- (void)showLoginSettings:(id)sender { [SMAppService openSystemSettingsLoginItems]; }
- (void)applicationDidBecomeActive:(NSNotification *)notification { if (self.loginStatus) [self refreshLoginStatus]; }
- (void)showSample:(id)sender {
    NSURL *sample = [NSBundle.mainBundle URLForResource:@"EPS-Test" withExtension:@"eps"];
    if (sample) [NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:@[sample]];
}
- (void)showReleases:(id)sender {
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"https://github.com/enesdigital/eps-finder/releases/latest"]];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc == 2 && [@(argv[1]) isEqual:@"--finish-install"]) {
            if (![NSBundle.mainBundle.bundlePath isEqual:@"/Applications/EPS Finder.app"]) return 1;
            for (NSRunningApplication *running in [NSRunningApplication runningApplicationsWithBundleIdentifier:@"local.epsfinder"]) {
                if (running.processIdentifier != NSProcessInfo.processInfo.processIdentifier) [running terminate];
            }
            NSError *error = nil;
            if (!EPSRetireOlderCopies(NSBundle.mainBundle.bundleURL, &error)) NSLog(@"Older EPS Finder copies could not be moved to Trash: %@", error);
            if (!EPSConfigureLogin(&error)) NSLog(@"Login registration needs attention: %@", error);
            return 0;
        }
        NSApplication *application = [NSApplication sharedApplication];
        EPSAppDelegate *delegate = [EPSAppDelegate new];
        application.delegate = delegate;
        [application setActivationPolicy:NSApplicationActivationPolicyRegular];
        [application run];
    }
    return 0;
}
