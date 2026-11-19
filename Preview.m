#import <QuickLookUI/QuickLookUI.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "Render.h"
#import <os/log.h>

@interface EPSPreviewProvider : QLPreviewProvider <QLPreviewingController>
@end

@implementation EPSPreviewProvider
- (void)providePreviewForFileRequest:(QLFilePreviewRequest *)request
                 completionHandler:(void (^)(QLPreviewReply *, NSError *))handler {
    QLPreviewReply *reply = [[QLPreviewReply alloc]
        initWithDataOfContentType:UTTypePDF contentSize:CGSizeMake(800, 600)
        dataCreationBlock:^NSData *(QLPreviewReply *reply, NSError **error) {
            NSData *data = EPSRenderPDF(request.fileURL, 15, error);
            if (!data && error && *error) os_log_error(OS_LOG_DEFAULT, "EPSFinder preview failure: %{public}@", (*error).domain);
            return data;
        }];
    handler(reply, nil);
}
@end

extern int NSExtensionMain(int argc, const char *argv[]);
int main(int argc, const char *argv[]) { return NSExtensionMain(argc, argv); }
