#import <Foundation/Foundation.h>
#import <JFFAsyncOperations/JFFAsyncOperations.h>

@class JNUrlSessionConnection;

@interface JNUrlSessionAsyncOperation : NSObject<JFFAsyncOperationInterface>

-(instancetype)initWithUrlSessionConnection:( JNUrlSessionConnection* )connection;

@end
