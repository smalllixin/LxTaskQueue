//
//  LxTaskRegister.h
//  LxTaskQueue
//
//  Created by lixin on 1/27/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LxTask.h"
#import "LxTaskStorage.h"

typedef void (^LxTaskExecutor)(id<NSCoding> data);
// Used for detect the enviroment that if the task could run.
// Eg. Task depends on network status.
@protocol LxTaskRequisition <NSObject>
- (BOOL)isTaskRunnable;
- (void)taskRunnableStatusChange:(void(^)(BOOL couldRun))listener;
@end

@interface LxTaskRegister : NSObject

- (void)regDataType:(int16_t)dataType executor:(LxTaskExecutor)executor;

- (void)regStorage:(id<LxTaskStorage>)storage;

- (void)regRequisition:(id<LxTaskRequisition>)requisition;

@end
