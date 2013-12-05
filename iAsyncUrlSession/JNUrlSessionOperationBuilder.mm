#import "JNUrlSessionOperationBuilder.h"

#import "JNUrlSessionAsyncOperation.h"
#import "JNUrlSessionConnection.h"
#import "JNUrlSessionConnectionCallbacks.h"


@implementation JNUrlSessionOperationBuilder

+(JFFAsyncOperation)asyncTempFileDownloadWithRequest:( NSURLRequest* )request
{
    return [ self asyncTempFileDownloadWithRequest: request
                                         authBlock: nil ];
}

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
                             urlSessionCallbackQueue:( NSOperationQueue* )queue
{
    JFFAsyncOperationInstanceBuilder adapterBuilder = ^id< JFFAsyncOperationInterface >(void)
    {
        JNUrlSessionConnectionCallbacks* callbacks = [ JNUrlSessionConnectionCallbacks new ];
        callbacks.httpsAuthenticationBlock = authBlock;
        
        JNUrlSessionConnection* connection =
        [ [ JNUrlSessionConnection alloc ] initWithSessionConfiguration: sessionConfig
                                                   sessionCallbackQueue: queue
                                                            httpRequest: request
                                                              callbacks: callbacks ];
        connection.shouldCopyTmpFileToCaches = YES;
        
        JNUrlSessionAsyncOperation* adapter =
        [ [ JNUrlSessionAsyncOperation alloc ] initWithUrlSessionConnection: connection ];
        
        return adapter;
    };
    
    JFFAsyncOperation result = buildAsyncOperationWithAdapterFactory( [ adapterBuilder copy ] );
    return result;
}

// TODO : use a separate cookie storage when Apple makes it work properly
+(NSURLSessionConfiguration*)defaultSessionConfig
{
    static NSHTTPCookieStorage* cookieStorage = [ NSHTTPCookieStorage sharedHTTPCookieStorage ];

    
    // @adk : "alloc init" does not work properly
/*
    static dispatch_once_t onceToken;
    dispatch_once( &onceToken, ^void(void)
    {
        cookieStorage = [ [ NSHTTPCookieStorage alloc ] init ];
    });
*/
    
    
    NSURLSessionConfiguration* config = [ NSURLSessionConfiguration defaultSessionConfiguration ];
    {
        config.HTTPCookieStorage = cookieStorage;
        config.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
        config.HTTPCookieStorage.cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;

#if DEBUG
        {
            // @adk : infinity does not work properly
            
            config.timeoutIntervalForRequest  = 0;//std::numeric_limits<NSTimeInterval>::infinity();
            config.timeoutIntervalForResource = 0;//std::numeric_limits<NSTimeInterval>::infinity();
        }
#endif
        config.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
        config.HTTPMaximumConnectionsPerHost = 1;
    }
    
    return config;
}

@end
