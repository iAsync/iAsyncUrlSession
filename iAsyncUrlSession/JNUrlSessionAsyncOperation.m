#import "JNUrlSessionAsyncOperation.h"

#import "JNUrlSessionConnection.h"

@interface JNUrlSessionAsyncOperation()

@property ( nonatomic ) JNUrlSessionConnection* connection;
@property ( nonatomic, copy ) JFFAsyncOperationInterfaceCancelHandler cancelHandler;

@end

@implementation JNUrlSessionAsyncOperation

#pragma mark -
#pragma mark Object Lifecycle
-(void)dealloc
{
    [ self->_connection cancel ];
    self->_connection = nil;
    self->_cancelHandler = nil;
}

-(instancetype)init
{
    [ self doesNotRecognizeSelector: _cmd ];
    return nil;
}

-(instancetype)initWithUrlSessionConnection:( JNUrlSessionConnection* )connection
{
    NSParameterAssert( nil != connection );
    
    self = [ super init ];
    if ( nil == self )
    {
        return nil;
    }
    
    self->_connection = connection;
    
    return self;
}


#pragma mark -
#pragma mark Callback hooks
-(JNDownloadToTempFileFinished)hookConnectionCompletionWithBlock:(JFFAsyncOperationInterfaceResultHandler)handler
{
    JNUrlSessionConnectionCallbacks* connectionCallbacks = self->_connection.callbacks;
    
    JNDownloadToTempFileFinished connectionCompletion = [ connectionCallbacks.completionBlock copy ];
    JFFAsyncOperationInterfaceResultHandler handlerCopy = [ handler copy ];
    
    JNDownloadToTempFileFinished completionHook = ^void( NSURL* tmpFileUrl, NSError* downloadError )
    {
        if ( nil != connectionCompletion )
        {
            connectionCompletion( tmpFileUrl, downloadError );
        }
        
        if ( nil != handlerCopy )
        {
            handlerCopy( tmpFileUrl, downloadError );
        }
    };

    return [ completionHook copy ];
}

-(JNDownloadToTempFileProgress)hookConnectionProgressWithBlock:(JFFAsyncOperationInterfaceProgressHandler)progress
{
    JNUrlSessionConnectionCallbacks* connectionCallbacks = self->_connection.callbacks;
    
    JNDownloadToTempFileProgress connectionProgress = [ connectionCallbacks.progressBlock copy ];
    JFFAsyncOperationInterfaceProgressHandler progressCopy = [ progress copy ];

    JNDownloadToTempFileProgress result = ^void( id<JNDownloadProgressInfo> progressInfo )
    {
        if ( nil != connectionProgress )
        {
            connectionProgress( progressInfo );
        }
        
        if ( nil != progressCopy )
        {
            progressCopy( progressInfo );
        }
    };
    
    
    return [ result copy ];
}

#pragma mark -
#pragma mark JFFAsyncOperationInterface
-(void)initializeWithResultHandler:(JFFAsyncOperationInterfaceResultHandler)handler
                     cancelHandler:(JFFAsyncOperationInterfaceCancelHandler)cancelHandler
                   progressHandler:(JFFAsyncOperationInterfaceProgressHandler)progress
{
    self.cancelHandler = cancelHandler;
    
    // For unit testing
    if ( ![ self->_connection isMemberOfClass: [ JNUrlSessionConnection class ] ] )
    {
        return;
    }
    
    JNUrlSessionConnectionCallbacks* connectionCallbacks = self->_connection.callbacks;
    {
        connectionCallbacks.completionBlock = [ self hookConnectionCompletionWithBlock: handler  ];
        connectionCallbacks.progressBlock   = [ self hookConnectionProgressWithBlock  : progress ];
    }
}


-(void)asyncOperationWithResultHandler:(JFFAsyncOperationInterfaceResultHandler)handler
                         cancelHandler:(JFFAsyncOperationInterfaceCancelHandler)cancelHandler
                       progressHandler:(JFFAsyncOperationInterfaceProgressHandler)progress
{
    [ self initializeWithResultHandler: handler
                         cancelHandler: cancelHandler
                       progressHandler: progress ];

    [ self->_connection start ];
}

-(void)cancel:(BOOL)canceled
{
    if ( canceled )
    {
        [ self->_connection cancel ];
    }

    if ( nil != self->_cancelHandler )
    {
        self->_cancelHandler( canceled );
    }

    self->_connection = nil;
    self->_cancelHandler = nil;
}

@end
