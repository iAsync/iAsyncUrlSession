//
//  JNUrlSessionConnectionBlocks.h
//  iAsyncUrlSession
//
//  Created by Oleksandr Dodatko on 11/28/13.
//  Copyright (c) 2013 iAsync. All rights reserved.
//

#ifndef iAsyncUrlSession_JNUrlSessionConnectionBlocks_h
#define iAsyncUrlSession_JNUrlSessionConnectionBlocks_h

#import <iAsyncUrlSession/JNUrlSessionBlocks.h>

typedef void(^JNProcessAuthenticationChallengeBlock)( NSURLAuthenticationChallenge* challenge, NS_CERTIFICATE_CHECK_COMPLETION_BLOCK  );


#endif
