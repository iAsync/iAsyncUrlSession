#import <Foundation/Foundation.h>

@class JNUrlSessionConnectionCallbacks;

@interface JNUrlSessionConnection : NSObject

-(instancetype)initWithSessionConfiguration:( NSURLSessionConfiguration* )sessionConfig
                       sessionCallbackQueue:( NSOperationQueue* )callbackQueue
                                httpRequest:( NSURLRequest* )httpRequest
                                  callbacks:( JNUrlSessionConnectionCallbacks* )callbacks;

@property ( nonatomic, readonly ) NSURLSessionConfiguration* sessionConfig;
@property ( nonatomic, readonly ) NSURLSession* session;

-(void)start;
-(void)cancel;

@end
