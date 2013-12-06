#import "JNUrlSessionConnection.h"

#include "iAsyncUrlSessionDefines.h"

#import "JNDownloadProgressInfoPOD.h"
#import "JNUrlSessionConnectionError.h"
#import "JNUrlSessionFileSystemError.h"

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
    NSParameterAssert( nil != sessionConfig );
    NSParameterAssert( nil != httpRequest   );
    
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
    
    NSParameterAssert( nil != self->_session       );
    NSParameterAssert( nil != self->_sessionConfig );
    NSParameterAssert( nil != self->_httpRequest   );
    
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
#if DEBUG
    NSLog(@"----------[%@]----------", NSStringFromSelector( _cmd ) );
    NSLog(@"bytesWritten              : %@", [ @( bytesWritten ) stringValue] );
    NSLog(@"totalBytesWritten         : %@", [ @( totalBytesWritten ) stringValue] );
    NSLog(@"totalBytesExpectedToWrite : %@", [ @( totalBytesExpectedToWrite ) stringValue] );
    NSLog(@"taskLength                : %@", [ @( [ downloadTask  countOfBytesReceived ] ) stringValue ] );
    NSLog(@"--------------------" );
#endif
    
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

    if ( self->_shouldCopyTmpFileToCaches )
    {
        // @adk : it should be safe enough to invoke "move" on main thread.
        // Since it does not involve a lot of file IO operations
        NSError* moveFileError = nil;
        NSURL* newLocation = [ [ self class ] moveFileToCaches: location
                                                         error: &moveFileError ];

        [ self onSuccessfulDownloadToTmpFile: newLocation
                               copyFileError: moveFileError ];
    }
    else
    {
        [ self onSuccessfulDownloadToTmpFile: location
                               copyFileError: nil ];
    }
}

-(void)onSuccessfulDownloadToTmpFile:(NSURL *)tmpFileUrl
                       copyFileError:( NSError* )copyFileError
{
    JNDownloadToTempFileFinished completionBlock = self->_callbacks.completionBlock;
    if ( nil != completionBlock )
    {
        if ( nil == copyFileError )
        {
            completionBlock( tmpFileUrl, nil );
        }
        else
        {
            JNUrlSessionFileSystemError* wrappedError = [ [ JNUrlSessionFileSystemError alloc ] initWithUnderlyingError: copyFileError ];
            completionBlock( nil, wrappedError );
        }
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
    
    NSLog( @"[%@] Error : %@", NSStringFromSelector(_cmd), error );
    NSLog( @"[%@] Request : %@", NSStringFromSelector(_cmd), self->_httpRequest );
    
    JNDownloadToTempFileFinished completionBlock = self->_callbacks.completionBlock;
    if ( nil != completionBlock )
    {
        JNUrlSessionConnectionError* wrappedError = [ [ JNUrlSessionConnectionError alloc ] initWithUnderlyingError: error ];
        
        completionBlock( nil, wrappedError );
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
    
    NSLog( @"[%@] Error : %@", NSStringFromSelector(_cmd), error );
    NSLog( @"[%@] Request : %@", NSStringFromSelector(_cmd), self->_httpRequest );
    
    JNDownloadToTempFileFinished completionBlock = self->_callbacks.completionBlock;
    if ( nil != completionBlock )
    {
        JNUrlSessionConnectionError* wrappedError = [ [ JNUrlSessionConnectionError alloc ] initWithUnderlyingError: error ];
        completionBlock( nil, wrappedError );
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
completionHandler:( NSCertificateCheckCompletionBlock )completionHandler
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
+(NSURL*)moveFileToCaches:( NSURL* )tmpFileUrl
                    error:( NSError** )error
{
    // copypasted from Apple's example
    
    NSFileManager* fileManager = [ NSFileManager defaultManager ];
    
    NSArray* URLs = [ fileManager URLsForDirectory: NSCachesDirectory
                                         inDomains: NSUserDomainMask ];
    NSURL* cachesDirectory = URLs[0];
    
    
    NSURL* downloadURL = tmpFileUrl;
    NSURL* originalURL = tmpFileUrl;
    
    NSString* tempFileName = [ originalURL lastPathComponent ];
    NSURL* destinationURL = [ cachesDirectory URLByAppendingPathComponent: tempFileName ];
    NSError* errorCopy = nil;
    
    [ fileManager removeItemAtURL: destinationURL
                            error: NULL ];

    
    BOOL success = [ fileManager moveItemAtURL: downloadURL
                                         toURL: destinationURL
                                         error: &errorCopy ];

    if ( success )
    {
        return destinationURL;
    }
    else
    {
        return nil;
    }
}

@end
