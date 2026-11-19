#import <QuickLookThumbnailing/QuickLookThumbnailing.h>
#import <ImageIO/ImageIO.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// Integration check for EPS-Test.eps: the dark artwork must span and be centered in the thumbnail.
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSCAssert(argc == 3, @"Pass sample EPS and output PNG paths");
        NSURL *input = [NSURL fileURLWithPath:@(argv[1])];
        NSURL *output = [NSURL fileURLWithPath:@(argv[2])];
        QLThumbnailGenerationRequest *request = [[QLThumbnailGenerationRequest alloc]
            initWithFileAtURL:input size:CGSizeMake(512, 512) scale:2
            representationTypes:QLThumbnailGenerationRequestRepresentationTypeThumbnail];
        __block BOOL done = NO;
        __block BOOL passed = NO;
        void (^finish)(BOOL) = ^(BOOL result) {
            dispatch_async(dispatch_get_main_queue(), ^{ passed = result; done = YES; });
        };
        [QLThumbnailGenerator.sharedGenerator generateBestRepresentationForRequest:request completionHandler:
         ^(QLThumbnailRepresentation *thumbnail, NSError *error) {
            if (!thumbnail) { NSLog(@"Thumbnail failed: %@", error); finish(NO); return; }
            CGImageRef image = thumbnail.CGImage;
            CGImageDestinationRef file = CGImageDestinationCreateWithURL((__bridge CFURLRef)output,
                (__bridge CFStringRef)UTTypePNG.identifier, 1, NULL);
            if (!file) { finish(NO); return; }
            CGImageDestinationAddImage(file, image, NULL);
            BOOL saved = CGImageDestinationFinalize(file);
            CFRelease(file);
            unsigned char pixels[64 * 64 * 4] = {0};
            CGColorSpaceRef color = CGColorSpaceCreateDeviceRGB();
            CGContextRef context = CGBitmapContextCreate(pixels, 64, 64, 8, 64 * 4, color,
                kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
            CGColorSpaceRelease(color);
            CGContextDrawImage(context, CGRectMake(0, 0, 64, 64), image);
            CGContextRelease(context);
            unsigned char *leftMiddle = pixels + (32 * 64 + 6) * 4;
            unsigned char *rightMiddle = pixels + (32 * 64 + 57) * 4;
            BOOL result = saved && leftMiddle[0] < 100 && rightMiddle[0] < 100;
            printf("Finder thumbnail: %zu x %zu; centered artwork: %s\n", CGImageGetWidth(image),
                   CGImageGetHeight(image), result ? "PASS" : "FAIL");
            finish(result);
        }];
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:20];
        while (!done && deadline.timeIntervalSinceNow > 0)
            [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        return done && passed ? 0 : 1;
    }
}
