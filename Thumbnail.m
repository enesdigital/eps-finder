#import <QuickLookThumbnailing/QuickLookThumbnailing.h>
#import <PDFKit/PDFKit.h>
#import "Render.h"
#import <os/log.h>

@interface EPSThumbnailProvider : QLThumbnailProvider
@end

@implementation EPSThumbnailProvider
- (void)provideThumbnailForFileRequest:(QLFileThumbnailRequest *)request
                    completionHandler:(void (^)(QLThumbnailReply *, NSError *))handler {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @autoreleasepool {
            NSError *error = nil;
            NSData *data = EPSRenderPDF(request.fileURL, 8, &error);
            if (!data) {
                os_log_error(OS_LOG_DEFAULT, "EPSFinder thumbnail failure: %{public}@", error.domain);
                handler(nil, error); return;
            }
            PDFDocument *document = [[PDFDocument alloc] initWithData:data];
            PDFPage *page = [document pageAtIndex:0];
            CGSize canvas = request.maximumSize;
            QLThumbnailReply *reply = [QLThumbnailReply replyWithContextSize:canvas drawingBlock:^BOOL(CGContextRef context) {
                if (!page) return NO;
                CGRect drawingBounds = CGContextGetClipBoundingBox(context);
                CGContextSetRGBFillColor(context, 1, 1, 1, 1);
                CGContextFillRect(context, drawingBounds);
                CGPDFPageRef reference = page.pageRef;
                CGRect bounds = CGPDFPageGetBoxRect(reference, kCGPDFMediaBox);
                CGFloat ratio = MIN(drawingBounds.size.width / bounds.size.width,
                                    drawingBounds.size.height / bounds.size.height);
                CGContextTranslateCTM(context, drawingBounds.origin.x + (drawingBounds.size.width - bounds.size.width * ratio) / 2,
                                      drawingBounds.origin.y + (drawingBounds.size.height - bounds.size.height * ratio) / 2);
                CGContextScaleCTM(context, ratio, ratio);
                CGContextTranslateCTM(context, -bounds.origin.x, -bounds.origin.y);
                CGContextDrawPDFPage(context, reference);
                return YES;
            }];
            handler(reply, nil);
        }
    });
}
@end

extern int NSExtensionMain(int argc, const char *argv[]);
int main(int argc, const char *argv[]) { return NSExtensionMain(argc, argv); }
