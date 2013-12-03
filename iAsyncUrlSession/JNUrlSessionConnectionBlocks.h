#ifndef iAsyncUrlSession_JNUrlSessionConnectionBlocks_h
#define iAsyncUrlSession_JNUrlSessionConnectionBlocks_h

#import <iAsyncUrlSession/JNUrlSessionBlocks.h>

@protocol JNDownloadProgressInfo;

typedef void(^JNProcessAuthenticationChallengeBlock)( NSURLAuthenticationChallenge* challenge, NSCertificateCheckCompletionBlock  );

typedef void(^JNDownloadToTempFileFinished)( NSURL* tmpFileUrl, NSError* downloadError );
typedef void(^JNDownloadToTempFileProgress)( id<JNDownloadProgressInfo> progressInfo );

#endif
