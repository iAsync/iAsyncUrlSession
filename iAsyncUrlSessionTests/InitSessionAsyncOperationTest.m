#import <XCTest/XCTest.h>

#import <objc/message.h>
#import <objc/runtime.h>

#import "MockSessionConnection.h"
#import "JNUrlSessionAsyncOperation.h"
#import <iAsyncUrlSession/iAsyncUrlSession.h>

static const int64_t bytesWritten              = 150;
static const int64_t totalBytesWritten         = 500;
static const int64_t totalBytesExpectedToWrite = 3872;



@interface InitSessionAsyncOperationTest : XCTestCase
@end

@implementation InitSessionAsyncOperationTest
{
    NSURLSessionConfiguration* _config;
    
    NSURL* _tmpFileUrl;
    
    NSURLRequest* _request;
    
    JNUrlSessionConnectionCallbacks* _nilCallbacks;
    
    NSURLProtectionSpace* _certificateSpace;
    NSURLAuthenticationChallenge* _mockChallenge;
    
    JNUrlSessionConnection* _connectionWithNilCallbacks;
    
    JNUrlSessionAsyncOperation* _operation;
}


-(void)setUp
{
    [ super setUp ];
    
    self->_tmpFileUrl = [ NSURL URLWithString: @"file:///tmp/downloaded.txt" ];
    
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
    
    self->_operation = [ [ JNUrlSessionAsyncOperation alloc ] initWithUrlSessionConnection: self->_connectionWithNilCallbacks ];
}

-(void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [ super tearDown ];
}

-(void)testUrlSessionOperationRejectsInit
{
    XCTAssertThrows
    (
       [ JNUrlSessionAsyncOperation new ],
       @"init is not supported"
    );
}

-(void)testUrlSessionOperationRejectsNilConnection
{
    XCTAssertThrows
    (
     [ [ JNUrlSessionAsyncOperation alloc ] initWithUrlSessionConnection: nil ],
     @"init is not supported"
    );
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"


#pragma mark -
#pragma mark Completion
-(void)testCompletionCallbackCanBeNil
{
    XCTAssertNotNil( self->_operation, @"operation not initialized properly" );
    
    objc_msgSend
    (
        self->_operation, @selector( initializeWithResultHandler:cancelHandler:progressHandler: ),
        nil, nil, nil
    );
    
    
    XCTAssertNoThrow
    (
        objc_msgSend
        (
         self->_connectionWithNilCallbacks, @selector(URLSession:downloadTask:didFinishDownloadingToURL:),
         self->_connectionWithNilCallbacks.session, nil, self->_tmpFileUrl
        ),
        @"nil callbacks should not cause crashes"
    );
}

-(void)testBothConnectionAndOperation_CompletionCallbacks_AreInvoked
{
    __block NSURL*   connectionResult;
    __block NSError* connectionError ;

    __block NSURL*   asyncOpResult;
    __block NSError* asyncOpError ;
    
    self->_nilCallbacks.completionBlock = ^void( NSURL* result, NSError* error)
    {
        connectionResult = result;
        connectionError  = error ;
    };
    
    JFFAsyncOperationInterfaceResultHandler asyncCompletion = ^void( NSURL* result, NSError* error)
    {
        asyncOpResult = result;
        asyncOpError  = error ;
    };
    
    objc_msgSend
    (
       self->_operation, @selector( initializeWithResultHandler:cancelHandler:progressHandler: ),
       asyncCompletion, nil, nil
    );
    
    
    objc_msgSend
    (
       self->_connectionWithNilCallbacks, @selector(URLSession:downloadTask:didFinishDownloadingToURL:),
       self->_connectionWithNilCallbacks.session, nil, self->_tmpFileUrl
    );
    
    XCTAssertNotNil( connectionResult, @"connectionResult must not be nil" );
    XCTAssertNotNil( asyncOpResult   , @"asyncOpResult must not be nil"    );
    
    XCTAssertNil( connectionError, @"connectionError must not be nil" );
    XCTAssertNil( asyncOpError   , @"asyncOpError must not be nil"    );
    
    XCTAssertEqualObjects( connectionResult, self->_tmpFileUrl, @"result mismatch" );
    XCTAssertEqualObjects( asyncOpResult   , self->_tmpFileUrl, @"result mismatch" );
    XCTAssertEqualObjects( connectionResult, asyncOpResult    , @"result mismatch" );
}

#pragma mark -
#pragma mark Progress
-(void)testProgressCallbackCanBeNil
{
    XCTAssertNotNil( self->_operation, @"operation not initialized properly" );
    
    objc_msgSend
    (
     self->_operation, @selector( initializeWithResultHandler:cancelHandler:progressHandler: ),
     nil, nil, nil
     );
    
    
    SEL delegateMethod = @selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:);
    
    XCTAssertNoThrow
    (
     objc_msgSend
     (
      self->_connectionWithNilCallbacks, delegateMethod,
      self->_connectionWithNilCallbacks.session, nil, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite
      ),
     @"nil callbacks should not cause crashes"
     );
}

-(void)testBothConnectionAndOperation_ProgressCallbacks_AreInvoked
{
    __block id<JNDownloadProgressInfo>   connectionResult;
    __block id<JNDownloadProgressInfo>   asyncOpResult   ;
    
    self->_nilCallbacks.progressBlock = ^void( id<JNDownloadProgressInfo> progressInfo)
    {
        connectionResult = progressInfo;
    };
    
    JFFAsyncOperationInterfaceProgressHandler asyncProgress = ^void( id<JNDownloadProgressInfo> progressInfo )
    {
        asyncOpResult = progressInfo;
    };
    
    objc_msgSend
    (
     self->_operation, @selector( initializeWithResultHandler:cancelHandler:progressHandler: ),
     nil, nil, asyncProgress
    );
    
    
    SEL delegateMethod = @selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:);
    
     objc_msgSend
     (
      self->_connectionWithNilCallbacks, delegateMethod,
      self->_connectionWithNilCallbacks.session, nil, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite
      );
    
    
    XCTAssertNotNil( connectionResult, @"connectionResult must not be nil" );
    XCTAssertNotNil( asyncOpResult   , @"asyncOpResult must not be nil"    );
    XCTAssertTrue( connectionResult == asyncOpResult, @"result mismatch" );
    
    XCTAssertTrue( [ asyncOpResult downloadedBytesCount ] == totalBytesWritten, @"totalBytesWritten mismatch" );
    XCTAssertTrue( [ asyncOpResult totalBytesCount ] == totalBytesExpectedToWrite, @"totalBytesExpectedToWrite mismatch" );
}

#pragma mark -
#pragma mark cancel
-(void)testCancelCallbackIsInvokedOnOperationCancel_YES
{
    __block BOOL result = NO;
    MockSessionConnection* mockConnection = [ MockSessionConnection new ];
    
    JFFAsyncOperationInterfaceCancelHandler cancelHandler = ^void( BOOL isNotUnsubscribeOnly )
    {
        result = isNotUnsubscribeOnly;
    };
    
    objc_msgSend
    (
       self->_operation, @selector( initializeWithResultHandler:cancelHandler:progressHandler: ),
       nil, cancelHandler, nil
    );
    
    objc_msgSend( self->_operation, @selector(setConnection:), mockConnection );
    [ self->_operation cancel: YES ];
    
    XCTAssertTrue( result, @"result mismatch" );
    XCTAssertTrue( 1 == [ mockConnection cancelInvocationCount ], @"cancelInvocationCount mismatch" );
    
    id connection = objc_msgSend( self->_operation, @selector(connection) );
    id connectionCancelCallback = objc_msgSend( self->_operation, @selector(cancelHandler) );
    
    XCTAssertNil( connection, @"connection cleanup not performad" );
    XCTAssertNil( connectionCancelCallback, @"connectionCancelCallback cleanup not performad" );
}

-(void)testCancelCallbackIsInvokedOnOperationCancel_NO
{
    __block BOOL result = YES;
    MockSessionConnection* mockConnection = [ MockSessionConnection new ];
    
    JFFAsyncOperationInterfaceCancelHandler cancelHandler = ^void( BOOL isNotUnsubscribeOnly )
    {
        result = isNotUnsubscribeOnly;
    };
    
    objc_msgSend
    (
     self->_operation, @selector( initializeWithResultHandler:cancelHandler:progressHandler: ),
     nil, cancelHandler, nil
     );
    
    objc_msgSend( self->_operation, @selector(setConnection:), mockConnection );
    [ self->_operation cancel: NO ];
    
    XCTAssertFalse( result, @"result mismatch" );
    XCTAssertTrue( 0 == [ mockConnection cancelInvocationCount ], @"cancelInvocationCount mismatch" );
    
    id connection = objc_msgSend( self->_operation, @selector(connection) );
    id connectionCancelCallback = objc_msgSend( self->_operation, @selector(cancelHandler) );
    
    XCTAssertNil( connection, @"connection cleanup not performad" );
    XCTAssertNil( connectionCancelCallback, @"connectionCancelCallback cleanup not performad" );
}

-(void)testStartIsPerformedOnCallbacksAssignment
{
    MockSessionConnection* mockConnection = [ MockSessionConnection new ];
    objc_msgSend( self->_operation, @selector(setConnection:), mockConnection );
    [ self->_operation asyncOperationWithResultHandler: nil
                                         cancelHandler: nil
                                       progressHandler: nil ];
    
    XCTAssertTrue( 1 == [ mockConnection startInvocationCount ], @"startInvocationCount mismatch" );
}

#pragma clang diagnostic pop

@end
