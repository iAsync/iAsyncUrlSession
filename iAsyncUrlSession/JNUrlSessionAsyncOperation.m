#import "JNUrlSessionAsyncOperation.h"

#import "JNUrlSessionConnection.h"

@implementation JNUrlSessionAsyncOperation
{
    JNUrlSessionConnection* _connection;
    JFFAsyncOperationInterfaceCancelHandler _cancelHandler;
}

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
//TODO : rewrite hooks with C++ templates

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
-(void)asyncOperationWithResultHandler:(JFFAsyncOperationInterfaceResultHandler)handler
                         cancelHandler:(JFFAsyncOperationInterfaceCancelHandler)cancelHandler
                       progressHandler:(JFFAsyncOperationInterfaceProgressHandler)progress
{
    self->_cancelHandler = [ cancelHandler copy ];
    
    JNUrlSessionConnectionCallbacks* connectionCallbacks = self->_connection.callbacks;
    {
        connectionCallbacks.completionBlock = [ self hookConnectionCompletionWithBlock: handler  ];
        connectionCallbacks.progressBlock   = [ self hookConnectionProgressWithBlock  : progress ];
    }
    
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
