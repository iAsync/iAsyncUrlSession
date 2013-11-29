#import <iAsyncUrlSession/JNUrlSessionConnectionBlocks.h>
#import <JFFAsyncOperations/JFFAsyncOperations.h>

#import <Foundation/Foundation.h>

@interface JNUrlSessionOperationBuilder : NSObject

+(JFFAsyncOperation)asyncTempFileDownloadWithRequest:( NSURLRequest* )request
                                           authBlock:( JNProcessAuthenticationChallengeBlock )authBlock;

+(JFFAsyncOperation)asyncTempFileDownloadWithRequest:( NSURLRequest* )request
                                           authBlock:( JNProcessAuthenticationChallengeBlock )authBlock
                                       sessionConfig:( NSURLSessionConfiguration* )sessionConfig
                             urlSessionCallbackQueue:( NSOperationQueue* )queue;

@end
