#import <Foundation/Foundation.h>

@protocol JNDownloadProgressInfo <NSObject>

-(int64_t)downloadedBytesCount;
-(int64_t)totalBytesCount;

@end
