#import "JNUrlSessionOperationBuilder.h"

#import "JNUrlSessionAsyncOperation.h"
#import "JNUrlSessionConnection.h"
#import "JNUrlSessionConnectionCallbacks.h"

@implementation JNUrlSessionOperationBuilder

+(JFFAsyncOperation)asyncTempFileDownloadWithRequest:( NSURLRequest* )request
                                           authBlock:( JNProcessAuthenticationChallengeBlock )authBlock
{
    NSOperationQueue* currentQueue = [ NSOperationQueue currentQueue ];
    
    return [ self asyncTempFileDownloadWithRequest: request
                                         authBlock: authBlock
                                     sessionConfig: [ self defaultSessionConfig ]
                           urlSessionCallbackQueue: currentQueue ];
}

+(JFFAsyncOperation)asyncTempFileDownloadWithRequest:( NSURLRequest* )request
                                           authBlock:( JNProcessAuthenticationChallengeBlock )authBlock
                                       sessionConfig:( NSURLSessionConfiguration* )sessionConfig
                             urlSessionCallbackQueue:( NSOperationQueue* )queue;
{
    JNUrlSessionConnectionCallbacks* callbacks = [ JNUrlSessionConnectionCallbacks new ];
    callbacks.httpsAuthenticationBlock = authBlock;
    
    JNUrlSessionConnection* connection =
    [ [ JNUrlSessionConnection alloc ] initWithSessionConfiguration: sessionConfig
                                               sessionCallbackQueue: queue
                                                        httpRequest: request
                                                          callbacks: callbacks ];
    JNUrlSessionAsyncOperation* adapter =
        [ [ JNUrlSessionAsyncOperation alloc ] initWithUrlSessionConnection: connection ];
    
    JFFAsyncOperationInstanceBuilder adapterBuilder = ^id< JFFAsyncOperationInterface >(void)
    {
        return adapter;
    };
    
    JFFAsyncOperation result = buildAsyncOperationWithAdapterFactory( [ adapterBuilder copy ] );
    return result;
}

// TODO : use a separate cookie storage when Apple makes it work properly
+(NSURLSessionConfiguration*)defaultSessionConfig
{
    NSURLSessionConfiguration* config = [ NSURLSessionConfiguration defaultSessionConfiguration ];
    {
        config.HTTPCookieStorage = [ NSHTTPCookieStorage sharedHTTPCookieStorage ];
        config.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
        config.HTTPCookieStorage.cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
        
        config.HTTPMaximumConnectionsPerHost = 1;
    }
    
    return config;
}

@end
