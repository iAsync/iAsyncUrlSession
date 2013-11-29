#import "MockSessionConnection.h"

@interface MockSessionConnection()

@property ( nonatomic ) int startInvocationCount ;
@property ( nonatomic ) int cancelInvocationCount;

@end


@implementation MockSessionConnection

-(void)start
{
    ++self->_startInvocationCount;
}

-(void)cancel
{
    ++self->_cancelInvocationCount;
}

@end
