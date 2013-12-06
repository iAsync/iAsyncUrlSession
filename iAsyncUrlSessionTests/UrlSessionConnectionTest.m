#import <XCTest/XCTest.h>

#import <objc/message.h>
#import <objc/runtime.h>

#import "iAsyncUrlSessionDefines.h"

#import "JNDownloadProgressInfoPOD.h"
#import <iAsyncUrlSession/iAsyncUrlSession.h>

@interface UrlSessionConnectionTest : XCTestCase
@end

@implementation UrlSessionConnectionTest
{
    NSURLSessionConfiguration* _config;
    
    NSURLRequest* _request;
    
    JNUrlSessionConnectionCallbacks* _nilCallbacks;
    
    NSURLProtectionSpace* _certificateSpace;
    NSURLAuthenticationChallenge* _mockChallenge;
    
    
    JNUrlSessionConnection* _connectionWithNilCallbacks;
}


-(void)setUp
{
    [ super setUp ];
    
    NSURL* url = [ NSURL URLWithString: @"https://github.com/iAsync/iAsyncUrlSession/raw/master/LICENSE" ];
    self->_request = [ NSURLRequest requestWithURL: url ];
    
    NSURLSessionConfiguration* config = [ NSURLSessionConfiguration defaultSessionConfiguration ];
    {
        config.HTTPCookieStorage = [ NSHTTPCookieStorage sharedHTTPCookieStorage ];
        config.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
        config.HTTPCookieStorage.cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    }
    self->_config = config;
    
    
    self->_nilCallbacks = [ JNUrlSessionConnectionCallbacks new ];
    self->_connectionWithNilCallbacks =
    [ [ JNUrlSessionConnection alloc ] initWithSessionConfiguration: self->_config
                                               sessionCallbackQueue: [ NSOperationQueue currentQueue ]
                                                        httpRequest: self->_request
                                                          callbacks: self->_nilCallbacks ];
    
    
    {
        self->_certificateSpace = [ [ NSURLProtectionSpace alloc ] initWithHost: @"github.com"
                                                                           port: 443
                                                                       protocol: @"https"
                                                                          realm: @"testing"
                                                           authenticationMethod: NSURLAuthenticationMethodServerTrust ];
        
        self->_mockChallenge =
        [ [ NSURLAuthenticationChallenge alloc ] initWithProtectionSpace: self->_certificateSpace
                                                      proposedCredential: nil
                                                    previousFailureCount: 0
                                                         failureResponse: nil
                                                                   error: nil
                                                                  sender: nil ];
    }
}

-(void)tearDown
{
    self->_config = nil;
    self->_request = nil;
    
    [ super tearDown ];
}

#pragma mark - 
#pragma mark Init
-(void)testConnectionRejectsInit
{
    XCTAssertThrows
    (
        [ [ JNUrlSessionConnection alloc ] init ],
        @"assert expected"
    );
}


#pragma mark -
#pragma mark Https Auth callback
-(void)testSessionConfigIsRequired
{
    XCTAssertThrows
    (
        [ [ JNUrlSessionConnection alloc ] initWithSessionConfiguration: nil
                                                   sessionCallbackQueue: [ NSOperationQueue currentQueue ]
                                                            httpRequest: self->_request
                                                              callbacks: self->_nilCallbacks ],
         @"session config is required"
     );
}

-(void)testSessionQueueIsRequired
{
    XCTAssertNoThrow
    (
     [ [ JNUrlSessionConnection alloc ] initWithSessionConfiguration: self->_config
                                                sessionCallbackQueue: nil
                                                         httpRequest: self->_request
                                                           callbacks: self->_nilCallbacks ],
     @"session config is required"
     );
}

-(void)testHttpRequestIsRequired
{
    XCTAssertThrows
    (
     [ [ JNUrlSessionConnection alloc ] initWithSessionConfiguration: self->_config
                                                sessionCallbackQueue: [ NSOperationQueue currentQueue ]
                                                         httpRequest: nil
                                                           callbacks: self->_nilCallbacks ],
     @"session config is required"
    );
}

-(void)testAuthenticateBlockIsOptional
{
    JNUrlSessionConnection* connection =
    [ [ JNUrlSessionConnection alloc ] initWithSessionConfiguration: self->_config
                                               sessionCallbackQueue: [ NSOperationQueue currentQueue ]
                                                        httpRequest: self->_request
                                                          callbacks: self->_nilCallbacks ];

    __block NSURLSessionAuthChallengeDisposition receivedDisposition;

    
    NSCertificateCheckCompletionBlock certificateCallback =
    ^void(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential)
    {
        receivedDisposition = disposition;
    };
    
    objc_msgSend
    (
       connection, @selector(URLSession:didReceiveChallenge:completionHandler:),
       connection.session, self->_mockChallenge, certificateCallback
    );
    
    
#if TRUST_ALL_CERTIFICATES_BY_DEFAULT
    XCTAssertTrue( NSURLSessionAuthChallengeUseCredential == receivedDisposition, @"credential must be used by default" );
#else
    XCTAssertTrue( NSURLSessionAuthChallengePerformDefaultHandling == receivedDisposition, @"default behaviour must not be changed" );
#endif

}

-(void)testAuthenticateBlockUsesDefaultBehaviour_ForNot_ServerTrust
{
    JNUrlSessionConnection* connection =
    [ [ JNUrlSessionConnection alloc ] initWithSessionConfiguration: self->_config
                                               sessionCallbackQueue: [ NSOperationQueue currentQueue ]
                                                        httpRequest: self->_request
                                                          callbacks: self->_nilCallbacks ];
    
    __block NSURLSessionAuthChallengeDisposition receivedDisposition;
    
    
    NSCertificateCheckCompletionBlock certificateCallback =
    ^void(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential)
    {
        receivedDisposition = disposition;
    };
    
    objc_msgSend
    (
     connection, @selector(URLSession:didReceiveChallenge:completionHandler:),
     connection.session, nil, certificateCallback
    );
    

    XCTAssertTrue( NSURLSessionAuthChallengePerformDefaultHandling == receivedDisposition, @"default behaviour must not be changed" );
}

#pragma mark -
#pragma mark Download errors
-(void)testCompleteWithError_WorksWith_Nil_CompletionBlock
{
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;
    
    NSError* mockError = [ NSError errorWithDomain: @"test.test.test"
                                              code: 100500
                                          userInfo: nil ];
    
    XCTAssertNoThrow(
        objc_msgSend
        (
           connection, @selector(URLSession:task:didCompleteWithError:),
           connection.session, nil, mockError
        ),
        @"nil callback should not cause exceptions"
    );
}

-(void)testCompleteWithError_Rejects_Nil_ErrorObject
{
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;
    
    XCTAssertNoThrow
    (
        objc_msgSend
        (
           connection, @selector(URLSession:task:didCompleteWithError:),
           connection.session, nil, nil
        ),
        @"nil error cannot be received from NSURLSession"
    );
}

-(void)testCompleteWithError_ForwardsToCallback_Error
{
    __block NSError* completionError  = nil;
    __block NSURL*   completionResult = nil;
    
    self->_nilCallbacks.completionBlock = ^void( NSURL* tmpFileUrl, NSError* downloadError )
    {
        completionResult = tmpFileUrl   ;
        completionError  = downloadError;
    };
    
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;
    
    NSError* mockError = [ NSError errorWithDomain: @"test.test.test"
                                              code: 100500
                                          userInfo: nil ];
    

    objc_msgSend
    (
        connection, @selector(URLSession:task:didCompleteWithError:),
        connection.session, nil, mockError
    );

    XCTAssertTrue( [ completionError isMemberOfClass: [ JNUrlSessionConnectionError class ] ], @"error class mismatch" );
    
    JNUrlSessionConnectionError* castedError = (JNUrlSessionConnectionError*)completionError;
    XCTAssertTrue( castedError.underlyingError == mockError, @"error pointers mismatch" );
    XCTAssertEqualObjects( castedError.underlyingError, mockError, @"error object mismatch" );

    XCTAssertNil( completionResult, @"nil result expected" );
}


-(void)testSessionBecomeInvalidWithError_WorksWith_Nil_CompletionBlock
{
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;
    
    NSError* mockError = [ NSError errorWithDomain: @"test.test.test"
                                              code: 100500
                                          userInfo: nil ];
    
    XCTAssertNoThrow
    (
        objc_msgSend
        (
            connection, @selector(URLSession:didBecomeInvalidWithError:),
            connection.session, mockError
        ),
        @"nil callback should not cause exceptions"
    );
}

-(void)testSessionBecomeInvalidWithError_Rejects_Nil_ErrorObject
{
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;
    
    XCTAssertNoThrow
    (
     objc_msgSend
     (
      connection, @selector(URLSession:didBecomeInvalidWithError:),
      connection.session, nil
      ),
     @"nil error cannot be received from NSURLSession"
    );
}

-(void)testSessionBecomeInvalidWithError_ForwardsToCallback_Error
{
    __block NSError* completionError  = nil;
    __block NSURL*   completionResult = nil;
    
    self->_nilCallbacks.completionBlock = ^void( NSURL* tmpFileUrl, NSError* downloadError )
    {
        completionResult = tmpFileUrl   ;
        completionError  = downloadError;
    };
    
    
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;
    
    NSError* mockError = [ NSError errorWithDomain: @"test.test.test"
                                              code: 100500
                                          userInfo: nil ];
    
    
    objc_msgSend
    (
     connection, @selector(URLSession:didBecomeInvalidWithError:),
     connection.session, mockError
     );
    
    XCTAssertTrue( [ completionError isMemberOfClass: [ JNUrlSessionConnectionError class ] ], @"error class mismatch" );
    JNUrlSessionConnectionError* castedError = (JNUrlSessionConnectionError*)completionError;
    
    XCTAssertTrue( castedError.underlyingError == mockError, @"error pointers mismatch" );
    XCTAssertEqualObjects( castedError.underlyingError, mockError, @"error object mismatch" );
    
    XCTAssertNil( completionResult, @"nil result expected" );
}


-(void)testConnection_ShouldNot_ReceiveResumeEvents
{
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;

    // constants with types must be used
    // to make objc_msgSend() work properly
    const int64_t zero = 0;
    const int64_t offset = 243;
    const int64_t total = 100500;
    
    XCTAssertNoThrow
    (
     objc_msgSend
     (
      connection, @selector(URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:),
      connection.session, nil, zero, total
      ),
     @"assert expected for non zero offset"
     );
    
    
    XCTAssertThrows
    (
     objc_msgSend
     (
      connection, @selector(URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:),
      connection.session, nil, offset, total
      ),
     @"assert expected for non zero offset"
    );
}

#pragma mark -
#pragma mark Done callback
-(void)testFinishDownloading_ShouldNot_ReceiveNilUrl
{
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;
    
    XCTAssertThrows
    (
     objc_msgSend
     (
      connection, @selector(URLSession:downloadTask:didFinishDownloadingToURL:),
      connection.session, nil, nil
      ),
     @"assert expected for nil URL"
    );
}

-(void)testFinishDownloading_Forwards_Url_ToCallback
{
    __block NSError* actualError;
    __block NSURL*   actualResult;
    
    JNDownloadToTempFileFinished completion = ^void( NSURL* result, NSError* downloadError )
    {
        actualError = downloadError;
        actualResult = result;
    };
    
    self->_nilCallbacks.completionBlock = completion;
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;
    
    NSURL* tmpFileUrl = [ NSURL URLWithString: @"file:///tmp/downloaded.txt" ];

     objc_msgSend
     (
      connection, @selector(URLSession:downloadTask:didFinishDownloadingToURL:),
      connection.session, nil, tmpFileUrl
      );

    XCTAssertNil( actualError, @"error mismatch" );
    XCTAssertEqualObjects( tmpFileUrl, actualResult, @"result mismatch" );
}

-(void)testFinishDownloading_Should_WorkWith_NilCallback
{
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;
    NSURL* tmpFileUrl = [ NSURL URLWithString: @"file:///tmp/downloaded.txt" ];
    
    XCTAssertNoThrow
    (
     objc_msgSend
     (
      connection, @selector(URLSession:downloadTask:didFinishDownloadingToURL:),
      connection.session, nil, tmpFileUrl
      ),
     @"assert expected for nil URL"
     );
}

#pragma mark -
#pragma mark Progress
-(void)testProgressCallbackCanBeNil
{
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;
    
    const int64_t bytesWritten              = 150;
    const int64_t totalBytesWritten         = 500;
    const int64_t totalBytesExpectedToWrite = 3872;
    
    
    SEL delegateMethod = @selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:);

    XCTAssertNoThrow
    (
        objc_msgSend
        (
           connection, delegateMethod,
           connection.session, nil, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite
        ),
        @"nil progress callback is ok"
    );
}

-(void)testProgressCallback_Receives_totalBytesWritten_AND_totalBytesExpectedToWrite
{
    __block id<JNDownloadProgressInfo> receivedProgressInfo = nil;
    
    JNDownloadToTempFileProgress progressBlock = ^void( id<JNDownloadProgressInfo> progressInfo )
    {
        receivedProgressInfo = progressInfo;
    };
    self->_nilCallbacks.progressBlock = progressBlock;
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;

    
    const int64_t bytesWritten              = 150;
    const int64_t totalBytesWritten         = 500;
    const int64_t totalBytesExpectedToWrite = 3872;
    
    
    SEL delegateMethod = @selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:);
    objc_msgSend
    (
        connection, delegateMethod,
        connection.session, nil, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite
    );
    
    XCTAssertNotNil( receivedProgressInfo, @"valid progress info expected" );
    XCTAssertTrue( [ receivedProgressInfo isMemberOfClass: [ JNDownloadProgressInfoPOD class ] ], @"progress info class mismatch" );
    
    
    XCTAssertTrue( [ receivedProgressInfo downloadedBytesCount ] == totalBytesWritten, @"downloadedBytesCount mismatch" );
    XCTAssertTrue( [ receivedProgressInfo totalBytesCount ] == totalBytesExpectedToWrite, @"totalBytesExpectedToWrite mismatch" );
}

#pragma mark -
#pragma mark Cleanup
-(void)testCancelledConnectionShouldNotStartAgain
{
    JNUrlSessionConnection* connection = self->_connectionWithNilCallbacks;
    [ connection start ];
    [ connection cancel ];
    
    XCTAssertThrows( [ connection start ], @"connection cannot be restarted" );
}


@end
