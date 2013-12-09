#import <iAsyncUrlSession/Error/JNAbstractUrlSessionError.h>

@interface JNUrlSessionConnectionError : JNAbstractUrlSessionError

-(BOOL)isUntrustedCertificateError;

@end
