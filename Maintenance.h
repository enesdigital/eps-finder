#import <Foundation/Foundation.h>

NSArray<NSURL *> *EPSOlderCopies(NSArray<NSURL *> *directories, NSURL *installedApp);
BOOL EPSRetireOlderCopies(NSURL *installedApp, NSError **error);
BOOL EPSConfigureLogin(NSError **error);
