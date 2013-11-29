@interface ReadmeDownloadAsyncTest : GHAsyncTestCase
@end

@implementation ReadmeDownloadAsyncTest
{
    NSURLRequest* _request;
    NSData* _expectedReadme;
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
}

-(void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [ super tearDown ];
}

-(void)testReadmeIsDownloadedCorrectly
{
    __block NSURL* tmpFileUrl = nil;
    
    SEL testMethod = _cmd;
    [ self prepare: testMethod ];
 
    JFFAsyncOperation loader =
    [ JNUrlSessionOperationBuilder asyncTempFileDownloadWithRequest: self->_request
                                                          authBlock: nil ];
    
    loader( nil, nil, ^void( id result, NSError* error )
    {
        tmpFileUrl = result;
        
        [ self notify: kGHUnitWaitStatusSuccess
          forSelector: testMethod ];
    });
    
    [ self waitForStatus: kGHUnitWaitStatusSuccess
                 timeout: 1000 ];
    
    NSData* receivedReadme = [ NSData dataWithContentsOfURL: tmpFileUrl ];
    GHAssertTrue( [ self->_expectedReadme isEqualToData: receivedReadme ], @"downloaded content mismatch" );
}

@end
