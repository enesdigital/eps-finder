#import <PDFKit/PDFKit.h>
#import "Render.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSFileManager *fm = NSFileManager.defaultManager;
        NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory()]
                            URLByAppendingPathComponent:NSUUID.UUID.UUIDString];
        NSCAssert([fm createDirectoryAtURL:directory withIntermediateDirectories:NO attributes:nil error:NULL], @"Create test directory");
        @try {
            NSURL *input = [directory URLByAppendingPathComponent:@"Türkçe % örnek.eps"];
            NSString *eps = @"%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 20 30 340 210\n"
                "0.1 0.4 0.9 setrgbcolor 20 30 320 180 rectfill\n"
                "1 1 1 setrgbcolor /Helvetica findfont 32 scalefont setfont 45 100 moveto (EPS Finder) show\nshowpage\n%%EOF\n";
            NSData *original = [eps dataUsingEncoding:NSUTF8StringEncoding];
            NSCAssert([original writeToURL:input atomically:YES], @"Write EPS");
            NSError *error = nil;
            NSData *pdf = EPSRenderPDF(input, 10, &error);
            NSCAssert(pdf != nil && error == nil, @"Valid EPS: %@", error);
            PDFDocument *document = [[PDFDocument alloc] initWithData:pdf];
            NSRect bounds = [[document pageAtIndex:0] boundsForBox:kPDFDisplayBoxMediaBox];
            NSCAssert(document.pageCount == 1 && fabs(bounds.size.width - 320) < 1 && fabs(bounds.size.height - 180) < 1,
                      @"EPS bounding box must crop to 320 by 180: %@", NSStringFromRect(bounds));
            NSCAssert([[NSData dataWithContentsOfURL:input] isEqual:original], @"Source must be unchanged");

            NSMutableData *binary = [NSMutableData dataWithLength:30];
            unsigned char *bytes = binary.mutableBytes;
            bytes[0] = 0xc5; bytes[1] = 0xd0; bytes[2] = 0xd3; bytes[3] = 0xc6;
            uint32_t fields[] = {CFSwapInt32HostToLittle(30), CFSwapInt32HostToLittle((uint32_t)original.length)};
            memcpy(bytes + 4, fields, sizeof(fields));
            bytes[28] = 255; bytes[29] = 255;
            [binary appendData:original];
            NSCAssert([binary writeToURL:input atomically:YES], @"Write DOS EPS");
            error = nil;
            NSCAssert(EPSRenderPDF(input, 5, &error) != nil, @"DOS binary EPS must render: %@", error);

            NSCAssert([@"invalid" writeToURL:input atomically:YES encoding:NSUTF8StringEncoding error:NULL], @"Write invalid input");
            error = nil;
            NSCAssert(EPSRenderPDF(input, 2, &error) == nil && error != nil, @"Reject invalid header");

            NSString *privateRead = @"%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 10 10\n(/etc/hosts) (r) file closefile\nshowpage\n";
            NSCAssert([privateRead writeToURL:input atomically:YES encoding:NSUTF8StringEncoding error:NULL], @"Write sandbox test");
            error = nil;
            NSCAssert(EPSRenderPDF(input, 3, &error) == nil && error != nil, @"SAFER must reject unrelated file reads");

            NSString *loop = @"%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 10 10\n{} loop\n";
            NSCAssert([loop writeToURL:input atomically:YES encoding:NSUTF8StringEncoding error:NULL], @"Write timeout test");
            error = nil;
            NSDate *start = NSDate.date;
            NSCAssert(EPSRenderPDF(input, 0.25, &error) == nil && error != nil, @"Infinite loop must time out");
            NSCAssert(-start.timeIntervalSinceNow < 3, @"Timeout must stop renderer promptly");
            NSCAssert([original writeToURL:input atomically:YES], @"Restore valid input");
            error = nil;
            NSCAssert(EPSRenderPDF(input, 5, &error) != nil, @"Engine must recover after timeout: %@", error);
            puts("PASS: cropped PDF, Unicode and percent in paths, unchanged source, binary EPS, invalid input, SAFER, timeout recovery");
        } @finally {
            [fm removeItemAtURL:directory error:NULL];
        }
    }
    return 0;
}
