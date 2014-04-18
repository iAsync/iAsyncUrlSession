#import <iAsyncUrlSession/JNDownloadProgressInfo.h>
#import <Foundation/Foundation.h>

@interface JNDownloadProgressInfoPOD : NSObject<JNDownloadProgressInfo>

@property ( nonatomic ) int64_t downloadedBytesCount;
@property ( nonatomic ) int64_t totalBytesCount     ;

@end
