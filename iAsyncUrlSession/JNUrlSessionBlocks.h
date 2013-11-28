#ifndef iAsyncUrlSession_JNUrlSessionBlocks_h
#define iAsyncUrlSession_JNUrlSessionBlocks_h

#import <Foundation/Foundation.h>

typedef void (^NS_CERTIFICATE_CHECK_COMPLETION_BLOCK)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential);

typedef void(^NS_DOWNLOAD_TASK_COMPLETION_BLOCK)(NSURL *location, NSURLResponse *response, NSError *error);

#endif
