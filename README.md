iAsyncUrlSession
================

Adapters to make iOS7 networking classes work as async operations in term sof [iAsync library](https://github.com/EmbeddedSources/iAsync/)

The **NSURLDownloadTask** is wrapped into a class which is similar to **NSURLConnection** and uses block callbacks to notify the user. It allows handling session events independently from other downloads. See the details below.

```
License : BSD
```

The library project has two static library targets. One of them contains the **JNUrlSessionConnection** class that depends only on **Foundation.framework**. The other target contains the mentioned connection class and wrappers for integration with iAsync.





# Rationale
iOS7 has brought the new [NSURLSession](https://developer.apple.com/Library/ios/documentation/Foundation/Reference/NSURLSession_class/Introduction/Introduction.html) API that offers a completely different approach of networking.

On the other hand, it introduces a challenge for those who got used to handling downloads separately. **NSURLSession** uses a **single delegate** object **for all tasks** leaving the work of events dispatching to developers. One can solve this task by applying any approach listed below :

1). Notifications

2). Emulate task delegates using a mutex ( **@synchronized()** block ).

```
Note: This approach is used in AFNetworking 2.0
```
3). Create a dedicated instance of NSURLSession for each networking task


####This library uses approach [3]
--------

#Features
1. Block based callbacks
2. Lock-free
3. Integration with iAsync
 
 

#Limitations
1. Only [NSURLSessionDownloadTask](http://developer.apple.com/Library/ios/documentation/Foundation/Reference/NSURLSessionDownloadTask_class/Reference/Reference.html#//apple_ref/occ/cl/NSURLSessionDownloadTask) is supported. Saving 
2. **Suspend** and **resume** operations are not supported
3. Background downloads are not supported





#Using JNUrlSessionConnection Class

This class is as simple as NSURLConnection. All you need is :

* Session configuration object
* HTTP request
* Subscribe to callbacks


```objective-c
    NSURLSessionConfiguration* sessionConfig = [ NSURLSessionConfiguration defaultSessionConfiguration ];

    NSURL* url = [ NSURL URLWithString: @"https://raw.github.com/iAsync/iAsyncUrlSession/master/README.md" ];
    NSURLRequest* request = [ NSURLRequest requestWithURL: url ];

    JNUrlSessionConnectionCallbacks* callbacks = [ JNUrlSessionConnectionCallbacks new ];
    callbacks.completionBlock = ^void( NSURL* temporaryFileUrl, NSError* blockError )
    {
        // Do work with downloaded data
    };
    
    
    JNUrlSessionConnection* connection =
    [ [ JNUrlSessionConnection alloc ] initWithSessionConfiguration: sessionConfig
                                               sessionCallbackQueue: [ NSOperationQueue mainQueue ]
                                                        httpRequest: request
                                                          callbacks: callbacks ];
    connection.shouldCopyTmpFileToCaches = YES;
    [ connection start ];

```


#Using JNUrlSessionConnection as an Asynchronous Operation

In order to avoid the [callback hell](http://tirania.org/blog/archive/2013/Aug-15.html) problem the integration with [iAsync](https://github.com/EmbeddedSources/iAsync) library has been implemented. Moreover, this integration makes the code look easier.

```objective-c
    NSURLSessionConfiguration* sessionConfig = [ NSURLSessionConfiguration defaultSessionConfiguration ];

    NSURL* url = [ NSURL URLWithString: @"https://raw.github.com/iAsync/iAsyncUrlSession/master/README.md" ];
    NSURLRequest* request = [ NSURLRequest requestWithURL: url ];
    
    
    
    JFFAsyncOperation* asyncDownload = 
    [ JNUrlSessionOperationBuilder  asyncTempFileDownloadWithRequest: request
                                                           authBlock: nil 
                                                       sessionConfig: sessionConfig
                                             urlSessionCallbackQueue: [ NSOperationQueue mainQueue ] ];
    
    
    JFFAsyncOperationProgressHandler progressCallbackBlock = nil;
    JFFCancelAsyncOperationHandler cancelCallbackBlock = nil;
    loader( progressCallbackBlock, cancelCallbackBlock, ^void( NSURL* temporaryFileUrl, NSError* blockError )
    {
         // Do work with downloaded data
    });
```
