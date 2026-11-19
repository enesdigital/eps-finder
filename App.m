#import <AppKit/AppKit.h>

@interface EPSAppDelegate : NSObject <NSApplicationDelegate>
@end
@implementation EPSAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
        [NSApp activateIgnoringOtherApps:YES];
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"EPS Finder";
        alert.informativeText = @"Finder’da bir EPS dosyası seçip boşluk tuşuna basın. Simge görünümünde küçük resimler de üretilir.\n\nÖnizleme görünmüyorsa Sistem Ayarları’nda ‘Uzantılar’ veya ‘Hızlı Bakış’ araması yapıp EPS Finder uzantılarını etkinleştirin.\n\nDosyalar yerel olarak işlenir; kaynak EPS değiştirilmez.";
        [alert addButtonWithTitle:@"Örnek dosyayı göster"];
        [alert addButtonWithTitle:@"Tamam"];
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
