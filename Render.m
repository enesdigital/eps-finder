#import "Render.h"
#import <CoreGraphics/CoreGraphics.h>
#include <time.h>
#include "iapi.h"
#include "ierrors.h"

static NSError *EPSFailure(NSString *message) {
    return [NSError errorWithDomain:@"local.epsfinder" code:1
                          userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(message, nil)}];
}

static double EPSNow(void) {
    struct timespec value;
    clock_gettime(CLOCK_MONOTONIC, &value);
    return value.tv_sec + value.tv_nsec / 1e9;
}

typedef struct { double deadline; unsigned calls; BOOL cancelled; } EPSDeadline;
static int EPSPoll(void *handle) {
    EPSDeadline *deadline = handle;
    if ((++deadline->calls & 255) == 0 && EPSNow() >= deadline->deadline) deadline->cancelled = YES;
    return deadline->cancelled ? -1 : 0;
}
static int EPSRead(void *handle, char *buffer, int length) { return 0; }
static int EPSDiscard(void *handle, const char *buffer, int length) { return length; }

NSData *EPSRenderPDF(NSURL *input, NSTimeInterval timeout, NSError **error) {
    if (!input.isFileURL || timeout <= 0) {
        if (error) *error = EPSFailure(@"error.invalidInput");
        return nil;
    }
    NSDictionary *values = [input resourceValuesForKeys:@[NSURLIsRegularFileKey, NSURLFileSizeKey] error:error];
    if (!values) return nil;
    // shortcut: 256 MB input and 64 MB PDF limits keep Finder responsive; raise only after profiling large artwork.
    if (![values[NSURLIsRegularFileKey] boolValue] || [values[NSURLFileSizeKey] unsignedLongLongValue] > 256ULL * 1024 * 1024) {
        if (error) *error = EPSFailure(@"error.inputTooLarge");
        return nil;
    }
    NSFileManager *fm = NSFileManager.defaultManager;
    static dispatch_semaphore_t engineLock;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        engineLock = dispatch_semaphore_create(1);
        unsetenv("GS_OPTIONS");
        unsetenv("GS_LIB");
        unsetenv("GS_FONTPATH");
        unsetenv("GS_DEVICE");
    });
    NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
                        URLByAppendingPathComponent:NSUUID.UUID.UUIDString isDirectory:YES];
    if (![fm createDirectoryAtURL:directory withIntermediateDirectories:NO
                      attributes:@{NSFilePosixPermissions: @0700} error:error]) return nil;
    BOOL engineLocked = NO;
    BOOL initialized = NO;
    void *instance = NULL;
    EPSDeadline deadline = {EPSNow() + timeout, 0, NO};
    @try {
        NSURL *source = [directory URLByAppendingPathComponent:@"input.eps"];
        NSURL *output = [directory URLByAppendingPathComponent:@"preview.pdf"];
        // Work on a private copy so rendering never writes beside the original.
        if (![fm copyItemAtURL:input toURL:source error:error]) return nil;
        NSFileHandle *file = [NSFileHandle fileHandleForReadingFromURL:source error:error];
        if (!file) return nil;
        NSData *header = [file readDataUpToLength:4 error:error];
        [file closeFile];
        const unsigned char *bytes = header.bytes;
        BOOL postscript = header.length >= 2 && bytes[0] == '%' && bytes[1] == '!';
        BOOL binaryEPS = header.length == 4 && bytes[0] == 0xc5 && bytes[1] == 0xd0 && bytes[2] == 0xd3 && bytes[3] == 0xc6;
        if (!postscript && !binaryEPS) {
            if (error) *error = EPSFailure(@"error.invalidHeader");
            return nil;
        }
        if (dispatch_semaphore_wait(engineLock, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)))) {
            if (error) *error = EPSFailure(@"error.busy");
            return nil;
        }
        engineLocked = YES;
        if (gsapi_new_instance(&instance, &deadline) < 0) {
            if (error) *error = EPSFailure(@"error.startFailed");
            return nil;
        }
        if (gsapi_set_arg_encoding(instance, GS_ARG_ENCODING_UTF8) < 0 ||
            gsapi_set_stdio(instance, EPSRead, EPSDiscard, EPSDiscard) < 0 ||
            gsapi_set_poll(instance, EPSPoll) < 0) {
            if (error) *error = EPSFailure(@"error.setupFailed");
            return nil;
        }
        NSArray<NSString *> *arguments = @[@"gs", @"-q", @"-P-", @"-dSAFER", @"-dBATCH", @"-dNOPAUSE", @"-dEPSCrop",
                           @"-dFirstPage=1", @"-dLastPage=1", @"-dAutoRotatePages=/None", @"-sDEVICE=pdfwrite",
                           @"-dCompatibilityLevel=1.7", [@"-sOutputFile=" stringByAppendingString:output.path],
                           @"-f", source.path];
        char *argv[arguments.count + 1];
        for (NSUInteger index = 0; index < arguments.count; index++) argv[index] = (char *)arguments[index].UTF8String;
        argv[arguments.count] = NULL;
        initialized = YES;
        int status = gsapi_init_with_args(instance, (int)arguments.count, argv);
        int exitStatus = gsapi_exit(instance);
        initialized = NO;
        if (deadline.cancelled) {
            if (error) *error = EPSFailure(@"error.timeout");
            return nil;
        }
        if ((status != 0 && status != gs_error_Quit) || exitStatus != 0) {
            if (error) *error = EPSFailure(@"error.renderFailed");
            return nil;
        }
        NSDictionary *attributes = [fm attributesOfItemAtPath:output.path error:error];
        if (!attributes) return nil;
        if ([attributes fileSize] > 64ULL * 1024 * 1024) {
            if (error) *error = EPSFailure(@"error.outputTooLarge");
            return nil;
        }
        NSData *pdf = [NSData dataWithContentsOfURL:output options:0 error:error];
        if (!pdf) return nil;
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)pdf);
        CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(provider);
        CGDataProviderRelease(provider);
        CGPDFPageRef page = document ? CGPDFDocumentGetPage(document, 1) : NULL;
        CGRect bounds = page ? CGPDFPageGetBoxRect(page, kCGPDFMediaBox) : CGRectZero;
        BOOL valid = page && isfinite(bounds.size.width) && isfinite(bounds.size.height)
            && bounds.size.width > 0 && bounds.size.height > 0
            && bounds.size.width <= 100000 && bounds.size.height <= 100000;
        if (document) CGPDFDocumentRelease(document);
        if (!valid) {
            if (error) *error = EPSFailure(@"error.invalidPage");
            return nil;
        }
        return pdf;
    } @finally {
        if (initialized) gsapi_exit(instance);
        if (instance) gsapi_delete_instance(instance);
        if (engineLocked) dispatch_semaphore_signal(engineLock);
        [fm removeItemAtURL:directory error:NULL];
    }
}
