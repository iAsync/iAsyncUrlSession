#import "JNUrlSessionConnection.h"

#include "iAsyncUrlSessionDefines.h"

#import "JNDownloadProgressInfoPOD.h"

@interface JNUrlSessionConnection() <NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property ( nonatomic ) NSURLSession* session;
@property ( nonatomic ) NSURLSessionDownloadTask* downloadTask;

@property ( nonatomic ) NSURLRequest* httpRequest;
@property ( nonatomic ) JNUrlSessionConnectionCallbacks* callbacks;

@end

@implementation JNUrlSessionConnection

-(void)cleanup
{
    self->_callbacks = nil;

    [ self->_session invalidateAndCancel ];
    self->_session = nil;
    self->_sessionConfig = nil;

    self->_downloadTask = nil;
}

-(void)dealloc
{
    [ self cleanup ];
}

-(instancetype)init
{
    [ self doesNotRecognizeSelector: _cmd ];
    return nil;
}

-(instancetype)initWithSessionConfiguration:( NSURLSessionConfiguration* )sessionConfig
                       sessionCallbackQueue:( NSOperationQueue* )callbackQueue
                                httpRequest:( NSURLRequest* )httpRequest
                                  callbacks:( JNUrlSessionConnectionCallbacks* )callbacks
{
    self = [ super init ];
    if ( nil == self )
    {
        return nil;
    }
    
    self->_sessionConfig = sessionConfig;
    self->_httpRequest   = httpRequest  ;
    self->_callbacks     = callbacks    ;
    
    [ self setupSessionWithConfig: sessionConfig
                    callbackQueue: callbackQueue ];
    
    return self;
}

-(void)setupSessionWithConfig:( NSURLSessionConfiguration* )sessionConfig
                callbackQueue:( NSOperationQueue* )callbackQueue
{
    NSURLSession* session = [ NSURLSession sessionWithConfiguration: sessionConfig
                                                           delegate: self
                                                      delegateQueue: callbackQueue ];
    self->_session = session;
}

-(void)start
{
    if ( nil != self->_downloadTask )
    {
        return;
    }
    
    NSURLSessionDownloadTask* task = [ self->_session downloadTaskWithRequest: self->_httpRequest ];
    self.downloadTask = task;

    [ task resume ];
}

-(void)cancel
{
    [ self->_downloadTask cancel ];
    [ self cleanup ];
}



#pragma mark -
#pragma mark NSURLSessionDelegate : Download progress
-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
     didWriteData:(int64_t)bytesWritten
totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    JNDownloadToTempFileProgress progressBlock = self->_callbacks.progressBlock;
    if ( nil == progressBlock )
    {
        return;
    }
    
    
    JNDownloadProgressInfoPOD* progressInfo = [ JNDownloadProgressInfoPOD new ];
    {
        progressInfo.totalBytesCount      = totalBytesExpectedToWrite;
        progressInfo.downloadedBytesCount = totalBytesWritten        ;
    }
    
    progressBlock( progressInfo );
}

-(void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSParameterAssert( nil != location );
    
    JNDownloadToTempFileFinished completionBlock = self->_callbacks.completionBlock;
    if ( nil != completionBlock )
    {
        completionBlock( location, nil );
    }
    
    [ self cleanup ];
}

-(void)URLSession:(NSURLSession *)session
             task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if ( nil == error )
    {
        // after session invalidation we still receive this callback
        
        // we should have reveived didFinishDownloadingToURL:
        // at this point

        return;
    }
    
    JNDownloadToTempFileFinished completionBlock = self->_callbacks.completionBlock;
    if ( nil != completionBlock )
    {
        completionBlock( nil, error );
    }
    
    [ self cleanup ];
}

-(void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error
{
    if ( nil == error )
    {
        // after session invalidation we still receive this callback
        
        // we should have reveived didFinishDownloadingToURL:
        // at this point
        
        return;
    }
    
    JNDownloadToTempFileFinished completionBlock = self->_callbacks.completionBlock;
    if ( nil != completionBlock )
    {
        completionBlock( nil, error );
    }
    
    [ self cleanup ];
}


#pragma mark -
#pragma mark NSURLSessionDelegate : Restart download
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSParameterAssert( 0 == fileOffset );
}


#pragma mark -
#pragma mark NSURLSessionDelegate : HTTPS authentication
-(void)URLSession:( NSURLSession* )session
didReceiveChallenge:( NSURLAuthenticationChallenge* )challenge
completionHandler:( NS_CERTIFICATE_CHECK_COMPLETION_BLOCK )completionHandler
{
    JNProcessAuthenticationChallengeBlock httpsBlock = self->_callbacks.httpsAuthenticationBlock;
    if ( nil != httpsBlock )
    {
        httpsBlock( challenge, completionHandler );
        return;
    }
    else
    {
#if TRUST_ALL_CERTIFICATES_BY_DEFAULT
        {
            NSString* authMethod = challenge.protectionSpace.authenticationMethod;
            BOOL isCertificateAuth = [ NSURLAuthenticationMethodServerTrust isEqualToString: authMethod ];

            if ( isCertificateAuth )
            {
                SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
                NSURLCredential* credential = [ NSURLCredential credentialForTrust: serverTrust ];
                
                completionHandler( NSURLSessionAuthChallengeUseCredential, credential );
            }
            else
            {
                completionHandler( NSURLSessionAuthChallengePerformDefaultHandling, nil );
            }
        }
#else
        {
            completionHandler( NSURLSessionAuthChallengePerformDefaultHandling, nil );
        }
#endif
    }
}


#pragma mark -
#pragma mark Utils
+(void)copyFileToCaches:( NSURL* )tmpFileUrl
{
    
}

+(JFFAsyncOperation)asyncCopyFileToCaches:( NSURL* )tmpFileUrl
{
    return asyncOperationWithSyncOperation(^id(NSError *__autoreleasing *outError)
    {
        [ self copyFileToCaches: tmpFileUrl ];
        return [ NSNull null ];
    } );
}

@end
