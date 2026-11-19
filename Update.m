#import "Update.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreServices/CoreServices.h>

static NSString *const EPSRepository = @"https://github.com/enesdigital/eps-finder";
static const int64_t EPSMaximumPackageSize = 256 * 1024 * 1024;

static NSError *EPSUpdateError(NSString *key) {
    return [NSError errorWithDomain:@"local.epsfinder.update" code:1
                          userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(key, nil)}];
}

static NSArray<NSString *> *EPSVersion(id value) {
    if (![value isKindOfClass:NSString.class]) return nil;
    NSString *version = [value hasPrefix:@"v"] ? [value substringFromIndex:1] : value;
    NSString *component = @"(0|[1-9][0-9]{0,8})";
    NSString *pattern = [NSString stringWithFormat:@"^%@\\.%@\\.%@\\z", component, component, component];
    if ([version rangeOfString:pattern options:NSRegularExpressionSearch].location == NSNotFound) return nil;
    return [version componentsSeparatedByString:@"."];
}

@implementation EPSUpdate
@end

BOOL EPSIsNewerVersion(NSString *candidate, NSString *installed) {
    NSArray *remote = EPSVersion(candidate), *local = EPSVersion(installed);
    // The first release used the two-component version 1.0.
    if (!local && [installed isKindOfClass:NSString.class]) local = EPSVersion([installed stringByAppendingString:@".0"]);
    if (!remote || !local) return NO;
    for (NSUInteger index = 0; index < 3; index++) {
        NSInteger a = [remote[index] integerValue], b = [local[index] integerValue];
        if (a != b) return a > b;
    }
    return NO;
}

EPSUpdate *EPSAvailableUpdate(NSData *data, NSString *installedVersion, NSError **error) {
    if (error) *error = nil;
    id release = data.length > 0 && data.length <= 2 * 1024 * 1024 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    NSArray *installed = EPSVersion(installedVersion);
    if (![release isKindOfClass:NSDictionary.class] || !installed ||
        ![release[@"draft"] isEqual:@NO] || ![release[@"prerelease"] isEqual:@NO] || !EPSVersion(release[@"tag_name"])) {
        if (error) *error = EPSUpdateError(@"update.invalidRelease");
        return nil;
    }
    NSArray *available = EPSVersion(release[@"tag_name"]);
    if (!EPSIsNewerVersion(release[@"tag_name"], installedVersion)) return nil;
    NSString *version = [available componentsJoinedByString:@"."];
    NSString *tag = release[@"tag_name"];
    NSString *releaseURL = [EPSRepository stringByAppendingFormat:@"/releases/tag/%@", tag];
    NSString *name = [NSString stringWithFormat:@"EPS-Finder-%@-universal-unsigned.pkg", version];
    NSString *packageURL = [EPSRepository stringByAppendingFormat:@"/releases/download/%@/%@", tag, name];
    if ([release[@"html_url"] isEqual:releaseURL] && [release[@"assets"] isKindOfClass:NSArray.class]) {
        for (id asset in release[@"assets"]) {
            if (![asset isKindOfClass:NSDictionary.class] || ![asset[@"name"] isEqual:name]) continue;
            id digest = asset[@"digest"], size = asset[@"size"];
            if (![asset[@"state"] isEqual:@"uploaded"] || ![asset[@"browser_download_url"] isEqual:packageURL] ||
                ![digest isKindOfClass:NSString.class] ||
                [digest rangeOfString:@"^sha256:[0-9a-f]{64}\\z" options:NSRegularExpressionSearch].location == NSNotFound ||
                ![size isKindOfClass:NSNumber.class] || [size doubleValue] != [size longLongValue] ||
                [size longLongValue] <= 0 || [size longLongValue] > EPSMaximumPackageSize) break;
            EPSUpdate *update = [EPSUpdate new];
            update.version = version;
            update.releaseURL = [NSURL URLWithString:releaseURL];
            update.packageURL = [NSURL URLWithString:packageURL];
            update.sha256 = [digest substringFromIndex:7];
            update.size = [size longLongValue];
            return update;
        }
    }
    if (error) *error = EPSUpdateError(@"update.invalidRelease");
    return nil;
}

BOOL EPSVerifyPackage(NSURL *file, EPSUpdate *update, NSError **error) {
    NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:file.path error:error];
    if (!attributes) return NO;
    if (![attributes[NSFileType] isEqual:NSFileTypeRegular] || [attributes fileSize] != (uint64_t)update.size ||
        update.size <= 0 || update.size > EPSMaximumPackageSize) {
        if (error) *error = EPSUpdateError(@"update.verificationFailed");
        return NO;
    }
    NSInputStream *stream = [NSInputStream inputStreamWithURL:file];
    [stream open];
    CC_SHA256_CTX context;
    CC_SHA256_Init(&context);
    uint8_t buffer[65536], digest[CC_SHA256_DIGEST_LENGTH];
    NSInteger count;
    while ((count = [stream read:buffer maxLength:sizeof(buffer)]) > 0) CC_SHA256_Update(&context, buffer, (CC_LONG)count);
    [stream close];
    CC_SHA256_Final(digest, &context);
    NSMutableString *hex = [NSMutableString new];
    for (NSUInteger index = 0; index < sizeof(digest); index++) [hex appendFormat:@"%02x", digest[index]];
    if (count < 0 || ![hex isEqual:update.sha256]) {
        if (error) *error = EPSUpdateError(@"update.verificationFailed");
        return NO;
    }
    return YES;
}

@interface EPSUpdater ()
@property(strong) NSURLSession *session;
@property(strong) EPSUpdate *update;
@property(copy) void (^progress)(double);
@property(copy) void (^completion)(NSURL *, NSError *);
@property(strong) NSError *downloadError;
@property(strong) NSURL *downloadedFile;
@end

@implementation EPSUpdater
- (instancetype)init {
    if ((self = [super init])) {
        NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
        configuration.timeoutIntervalForRequest = 30;
        configuration.timeoutIntervalForResource = 600;
        configuration.HTTPCookieStorage = nil;
        configuration.URLCredentialStorage = nil;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        NSOperationQueue *queue = [NSOperationQueue new];
        queue.maxConcurrentOperationCount = 1;
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
    }
    return self;
}
- (void)checkFromVersion:(NSString *)version completion:(void (^)(EPSUpdate *, NSError *))completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
        [NSURL URLWithString:@"https://api.github.com/repos/enesdigital/eps-finder/releases/latest"]];
    request.timeoutInterval = 20;
    [request setValue:@"application/vnd.github+json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"2026-03-10" forHTTPHeaderField:@"X-GitHub-Api-Version"];
    [request setValue:[@"EPS-Finder/" stringByAppendingString:version] forHTTPHeaderField:@"User-Agent"];
    [[self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        NSError *error = nil;
        EPSUpdate *update = nil;
        NSInteger status = [response isKindOfClass:NSHTTPURLResponse.class] ? [(NSHTTPURLResponse *)response statusCode] : 0;
        if (networkError || status != 200) error = EPSUpdateError(status == 403 || status == 429 ? @"update.rateLimited" : @"update.checkFailed");
        else update = EPSAvailableUpdate(data, version, &error);
        dispatch_async(dispatch_get_main_queue(), ^{ completion(update, error); });
    }] resume];
}
- (void)download:(EPSUpdate *)update progress:(void (^)(double))progress completion:(void (^)(NSURL *, NSError *))completion {
    self.update = update;
    self.progress = progress;
    self.completion = completion;
    self.downloadError = nil;
    self.downloadedFile = nil;
    [[self.session downloadTaskWithURL:update.packageURL] resume];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler {
    NSSet *hosts = [NSSet setWithArray:@[@"api.github.com", @"github.com", @"release-assets.githubusercontent.com", @"objects.githubusercontent.com"]];
    BOOL allowed = [request.URL.scheme isEqual:@"https"] && [hosts containsObject:request.URL.host] &&
                   !request.URL.user && !request.URL.password && (!request.URL.port || request.URL.port.integerValue == 443);
    completionHandler(allowed ? request : nil);
}
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task
      didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)total totalBytesExpectedToWrite:(int64_t)expected {
    if (total > self.update.size || total > EPSMaximumPackageSize) {
        self.downloadError = EPSUpdateError(@"update.verificationFailed");
        [task cancel];
    } else {
        double fraction = (double)total / self.update.size;
        dispatch_async(dispatch_get_main_queue(), ^{ if (self.progress) self.progress(fraction); });
    }
}
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task didFinishDownloadingToURL:(NSURL *)location {
    NSError *error = nil;
    NSInteger status = [task.response isKindOfClass:NSHTTPURLResponse.class] ? [(NSHTTPURLResponse *)task.response statusCode] : 0;
    if (status != 200) error = EPSUpdateError(@"update.downloadFailed");
    else EPSVerifyPackage(location, self.update, &error);
    NSFileManager *manager = NSFileManager.defaultManager;
    NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
                        URLByAppendingPathComponent:[@"EPS-Finder-Update-" stringByAppendingString:NSUUID.UUID.UUIDString] isDirectory:YES];
    NSURL *package = [directory URLByAppendingPathComponent:self.update.packageURL.lastPathComponent];
    if (!error && [manager createDirectoryAtURL:directory withIntermediateDirectories:NO
                                   attributes:@{NSFilePosixPermissions: @0700} error:&error]) {
        if ([manager moveItemAtURL:location toURL:package error:&error]) {
            NSDictionary *quarantine = @{(__bridge NSString *)kLSQuarantineTypeKey: (__bridge NSString *)kLSQuarantineTypeOtherDownload,
                                          (__bridge NSString *)kLSQuarantineDataURLKey: self.update.packageURL,
                                          (__bridge NSString *)kLSQuarantineOriginURLKey: self.update.releaseURL};
            [package setResourceValue:quarantine forKey:NSURLQuarantinePropertiesKey error:&error];
        }
    }
    if (error) {
        [manager removeItemAtURL:directory error:nil];
        self.downloadError = error;
    } else self.downloadedFile = package;
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (![task isKindOfClass:NSURLSessionDownloadTask.class]) return;
    NSError *failure = self.downloadError ?: (error || !self.downloadedFile ? EPSUpdateError(@"update.downloadFailed") : nil);
    NSURL *file = self.downloadedFile;
    dispatch_async(dispatch_get_main_queue(), ^{
        void (^completion)(NSURL *, NSError *) = self.completion;
        self.completion = nil;
        self.progress = nil;
        if (completion) completion(file, failure);
    });
}
- (void)cancel { [self.session invalidateAndCancel]; }
@end
