#ifndef iAsyncUrlSession_JNUrlSessionBlocks_h
#define iAsyncUrlSession_JNUrlSessionBlocks_h

#import <Foundation/Foundation.h>

typedef void (^NSCertificateCheckCompletionBlock)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential);

typedef void(^NSDownloadTaskCompletionBlock)(NSURL *location, NSURLResponse *response, NSError *error);

#endif
