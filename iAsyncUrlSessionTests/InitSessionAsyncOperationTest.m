#import <XCTest/XCTest.h>

#import <iAsyncUrlSession/iAsyncUrlSession.h>

@interface InitSessionAsyncOperationTest : XCTestCase
@end

@implementation InitSessionAsyncOperationTest

-(void)setUp
{
    [ super setUp ];
    // Put setup code here; it will be run once, before the first test case.
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

@end
