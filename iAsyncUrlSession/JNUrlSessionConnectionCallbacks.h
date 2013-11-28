#import <iAsyncUrlSession/JNUrlSessionConnectionBlocks.h>
#import <Foundation/Foundation.h>


@interface JNUrlSessionConnectionCallbacks : NSObject

@property ( nonatomic, copy ) JNProcessAuthenticationChallengeBlock httpsAuthenticationBlock;
@property ( nonatomic, copy ) JNDownloadToTempFileFinished completionBlock;
@property ( nonatomic, copy ) JNDownloadToTempFileProgress progressBlock;

@end
