#import <Foundation/Foundation.h>

@interface EPSUpdate : NSObject
@property(copy) NSString *version;
@property(copy) NSURL *packageURL;
@property(copy) NSURL *releaseURL;
@property(copy) NSString *sha256;
@property int64_t size;
@end

EPSUpdate *EPSAvailableUpdate(NSData *data, NSString *installedVersion, NSError **error);
BOOL EPSIsNewerVersion(NSString *candidate, NSString *installed);
BOOL EPSVerifyPackage(NSURL *file, EPSUpdate *update, NSError **error);

@interface EPSUpdater : NSObject <NSURLSessionDownloadDelegate>
- (void)checkFromVersion:(NSString *)version completion:(void (^)(EPSUpdate *, NSError *))completion;
- (void)download:(EPSUpdate *)update progress:(void (^)(double))progress completion:(void (^)(NSURL *, NSError *))completion;
- (void)cancel;
@end
