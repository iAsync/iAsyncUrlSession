#import <iAsyncUrlSession/JNUrlSessionConnectionBlocks.h>
#import <Foundation/Foundation.h>


@interface JNUrlSessionConnectionCallbacks : NSObject

@property ( nonatomic, copy ) JNProcessAuthenticationChallengeBlock authenticationBlock;

@end
