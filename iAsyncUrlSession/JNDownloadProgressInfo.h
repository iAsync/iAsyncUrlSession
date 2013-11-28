#import <Foundation/Foundation.h>

@protocol JNDownloadProgressInfo <NSObject>

-(uint64_t)downloadedBytesCount;
-(uint64_t)totalBytesCount;

@end
