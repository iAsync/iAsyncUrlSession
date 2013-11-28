#import <iAsyncUrlSession/JNDownloadProgressInfo.h>
#import <Foundation/Foundation.h>

@interface JNDownloadProgressInfoPOD : NSObject<JNDownloadProgressInfo>

@property ( nonatomic ) uint64_t downloadedBytesCount;
@property ( nonatomic ) uint64_t totalBytesCount     ;

@end
