#import <Foundation/Foundation.h>

@interface MockSessionConnection : NSObject

-(void)start;
-(void)cancel;

-(int)startInvocationCount;
-(int)cancelInvocationCount;

@end
