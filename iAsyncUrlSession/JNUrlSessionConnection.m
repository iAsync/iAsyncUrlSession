#import "JNUrlSessionConnection.h"

#define TRUST_ALL_CERTIFICATES 1


@interface JNUrlSessionConnection() <NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property ( nonatomic ) NSURLSession* session;
@property ( nonatomic ) NSURLSessionDownloadTask* downloadTask;

@property ( nonatomic ) NSURLRequest* httpRequest;

@end

@implementation JNUrlSessionConnection

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
    self->_httpRequest = httpRequest;
    
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
    
    // notify callbacks
}


#pragma mark -
#pragma mark NSURLSessionDelegate : Download progress
-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
     didWriteData:(int64_t)bytesWritten
totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"----------[%@]----------", NSStringFromSelector( _cmd ) );
    NSLog(@"bytesWritten              : %@", [ @( bytesWritten ) stringValue] );
    NSLog(@"totalBytesWritten         : %@", [ @( totalBytesWritten ) stringValue] );
    NSLog(@"totalBytesExpectedToWrite : %@", [ @( totalBytesExpectedToWrite ) stringValue] );
    NSLog(@"taskLength                : %@", [ @( [ downloadTask  countOfBytesReceived ] ) stringValue ] );
    NSLog(@"--------------------" );
}


- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSLog( @"CSV file : %@ ", location.absoluteString );
    NSLog( @"CSV file : %@ ", location.path );
    NSLog( @"------" );
}

-(void)URLSession:(NSURLSession *)session
             task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    
}

-(void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error
{
    
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
    // IDLE
    NSAssert( NO, @"Download suspend/resume is not supported" );
}


#pragma mark -
#pragma mark NSURLSessionDelegate : HTTPS authentication


#if TRUST_ALL_CERTIFICATES
-(void)URLSession:( NSURLSession* )session
didReceiveChallenge:( NSURLAuthenticationChallenge* )challenge
completionHandler:( NS_CERTIFICATE_CHECK_COMPLETION_BLOCK )completionHandler
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
#endif

@end
