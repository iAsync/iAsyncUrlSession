@interface ReadmeDownloadConnectionAsyncTest : GHAsyncTestCase

@end

@implementation ReadmeDownloadConnectionAsyncTest
{
    NSURLRequest* _request;
    NSData* _expectedReadme;
    
    NSURLSessionConfiguration* _config;
    NSOperationQueue* _mainQueue;
}


-(void)setUp
{
    [ super setUp ];
    
    NSURL* url = [ NSURL URLWithString: @"https://raw.github.com/iAsync/iAsyncUrlSession/master/README.md" ];
    NSURLRequest* request = [ NSURLRequest requestWithURL: url ];
    self->_request = request;
    
    NSString* readmePath = [ [ NSBundle mainBundle ] pathForResource: @"README"
                                                              ofType: @"md" ];
    self->_expectedReadme = [ NSData dataWithContentsOfFile: readmePath ];
    
    
    self->_config = [ NSURLSessionConfiguration defaultSessionConfiguration ];
    self->_mainQueue = [ NSOperationQueue mainQueue ];
}

-(void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [ super tearDown ];
}

-(void)testReadmeIsDownloadedCorrectly
{
    __block NSURL* tmpFileUrl = nil;
    __block NSData* receivedReadme = nil;
    __block NSError* error = nil;
    
    SEL testMethod = _cmd;
    [ self prepare: testMethod ];

    
    JNUrlSessionConnectionCallbacks* callbacks = [ JNUrlSessionConnectionCallbacks new ];
    callbacks.completionBlock = ^void( NSURL* blockResult, NSError* blockError )
    {
        tmpFileUrl = blockResult;
        error = blockError;
        
        receivedReadme = [ NSData dataWithContentsOfURL: tmpFileUrl ];
        
        [ self notify: kGHUnitWaitStatusSuccess
          forSelector: testMethod ];
    };
    
    JNUrlSessionConnection* connection =
    [ [ JNUrlSessionConnection alloc ] initWithSessionConfiguration: self->_config
                                               sessionCallbackQueue: self->_mainQueue
                                                        httpRequest: self->_request
                                                          callbacks: callbacks ];
    connection.shouldCopyTmpFileToCaches = NO;
    [ connection start ];
    
    [ self waitForStatus: kGHUnitWaitStatusSuccess
                 timeout: 1000 ];
    
    GHAssertTrue( [ self->_expectedReadme isEqualToData: receivedReadme ], @"downloaded content mismatch" );
    
    receivedReadme = [ NSData dataWithContentsOfURL: tmpFileUrl ];
    GHAssertNil( receivedReadme, @"URL from the callback should no longer be valid" );
}

-(void)testReadmeIsDownloadedCorrectlyAndAccessibleOutsideCallbacks
{
    __block NSURL* tmpFileUrl = nil;
    __block NSData* receivedReadme = nil;
    __block NSError* error = nil;
    
    SEL testMethod = _cmd;
    [ self prepare: testMethod ];
    
    
    JNUrlSessionConnectionCallbacks* callbacks = [ JNUrlSessionConnectionCallbacks new ];
    callbacks.completionBlock = ^void( NSURL* blockResult, NSError* blockError )
    {
        tmpFileUrl = blockResult;
        error = blockError;
        
        [ self notify: kGHUnitWaitStatusSuccess
          forSelector: testMethod ];
    };
    
    JNUrlSessionConnection* connection =
    [ [ JNUrlSessionConnection alloc ] initWithSessionConfiguration: self->_config
                                               sessionCallbackQueue: self->_mainQueue
                                                        httpRequest: self->_request
                                                          callbacks: callbacks ];
    connection.shouldCopyTmpFileToCaches = YES;
    [ connection start ];
    
    [ self waitForStatus: kGHUnitWaitStatusSuccess
                 timeout: 1000 ];
    
    receivedReadme = [ NSData dataWithContentsOfURL: tmpFileUrl ];
    GHAssertTrue( [ self->_expectedReadme isEqualToData: receivedReadme ], @"downloaded content mismatch" );
}

@end
