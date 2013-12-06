#import <Foundation/Foundation.h>

@interface JNAbstractUrlSessionError : NSError

-(instancetype)initWithUnderlyingError:( NSError* )error;

@property ( nonatomic, readonly ) NSError* underlyingError;

@end
