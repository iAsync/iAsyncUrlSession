#import "JNAbstractUrlSessionError.h"

@implementation JNAbstractUrlSessionError

-(instancetype)initWithUnderlyingError:( NSError* )error
{
    self = [ super initWithDomain: @"org.iasync.NSUrlSessionConnection"
                             code: 1
                         userInfo: nil ];
    if ( nil == self )
    {
        return nil;
    }
    
    self->_underlyingError = error;
    
    return self;
}

-(id)init
{
    [ self doesNotRecognizeSelector: _cmd ];
    return nil;
}

-(id)initWithDomain:(NSString *)domain
               code:(NSInteger)code
           userInfo:(NSDictionary *)dict
{
    [ self doesNotRecognizeSelector: _cmd ];
    return nil;
}



@end
