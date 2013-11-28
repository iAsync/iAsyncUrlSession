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

-(void)dealloc
{
    self->_callbacks = nil;
    [ self cancel ];
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
    NSURLSessionDownloadTask* task = [ self->_session downloadTaskWithRequest: self->_httpRequest ];
    self.downloadTask = task;

    [ task resume ];
}

-(void)cancel
{
    [ self->_downloadTask cancel ];

    self->_downloadTask = nil;
    self->_session = nil;
    self->_sessionConfig = nil;
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

    JNDownloadProgressInfoPOD* progressInfo = [ JNDownloadProgressInfoPOD new ];
    {
        progressInfo.totalBytesCount      = totalBytesExpectedToWrite;
        progressInfo.downloadedBytesCount = totalBytesWritten        ;
    }
    
    progressBlock( progressInfo );
    
//    NSLog(@"----------[%@]----------", NSStringFromSelector( _cmd ) );
//    NSLog(@"bytesWritten              : %@", [ @( bytesWritten ) stringValue] );
//    NSLog(@"totalBytesWritten         : %@", [ @( totalBytesWritten ) stringValue] );
//    NSLog(@"totalBytesExpectedToWrite : %@", [ @( totalBytesExpectedToWrite ) stringValue] );
//    NSLog(@"taskLength                : %@", [ @( [ downloadTask  countOfBytesReceived ] ) stringValue ] );
//    NSLog(@"--------------------" );
}


- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSParameterAssert( nil != location );
    
    JNDownloadToTempFileFinished completionBlock = self->_callbacks.completionBlock;
    if ( nil != completionBlock )
    {
        completionBlock( location, nil );
    }
    
//    NSLog( @"CSV file : %@ ", location.absoluteString );
//    NSLog( @"CSV file : %@ ", location.path );
//    NSLog( @"------" );
}

-(void)URLSession:(NSURLSession *)session
             task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    // @adk - ???
    NSParameterAssert( nil != error );
    
    JNDownloadToTempFileFinished completionBlock = self->_callbacks.completionBlock;
    if ( nil != completionBlock )
    {
        completionBlock( nil, error );
    }
}

-(void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error
{
    NSParameterAssert( nil != error );
    
    JNDownloadToTempFileFinished completionBlock = self->_callbacks.completionBlock;
    if ( nil != completionBlock )
    {
        completionBlock( nil, error );
    }
}


//#pragma mark -
//#pragma mark NSURLSessionDelegate : Redirect
//- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
//willPerformHTTPRedirection:(NSHTTPURLResponse *)response
//        newRequest:(NSURLRequest *)request
// completionHandler:(void (^)(NSURLRequest *))completionHandler
//{
//}

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

@end
