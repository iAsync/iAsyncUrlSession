#import "JNUrlSessionConnectionError.h"

@implementation JNUrlSessionConnectionError

-(BOOL)isUntrustedCertificateError
{
    BOOL isNetworkError = [ self.underlyingError.domain isEqualToString: @"NSURLErrorDomain" ];
    BOOL isBadCertificateError = ( self.underlyingError.code == -1202 );
    
    
    return isNetworkError && isBadCertificateError;
}

@end
