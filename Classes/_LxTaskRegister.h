//
//  _LxTaskRegister.h
//  LxTaskQueue
//
//  Created by lixin on 1/27/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#ifndef LxTaskQueue__LxTaskRegister_h
#define LxTaskQueue__LxTaskRegister_h

#import "LxTaskRegister.h"

@interface LxTaskRegister()

- (NSDictionary*)executorMap;

- (NSDictionary*)cancelListenerMap;

- (id<LxTaskStorage>)storage;

- (id<LxTaskRequisition>)requisition;

- (NSInteger)maxRetryCount;

@end

#endif
