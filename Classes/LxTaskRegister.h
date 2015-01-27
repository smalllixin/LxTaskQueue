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

typedef NS_ENUM(NSUInteger, LxTaskCompleteResult) {
    LxTaskCompleteResultOk = 0,
    LxTaskCompleteResultFailed,
    LxTaskCompleteResultNeedRetry
};

typedef void (^LxTaskCompleteMarker)(LxTask *task, LxTaskCompleteResult result);
typedef void (^LxTaskExecutor)(LxTask *task, LxTaskCompleteMarker completeMaker);
typedef void (^LxTaskCancelListener)(LxTask *task);

// Used for detect the enviroment that if the task could run.
// Eg. Task depends on network status.
@protocol LxTaskRequisition <NSObject>

- (BOOL)isTaskRunnable;
- (void)taskRunnableStatusChange:(void(^)(BOOL couldRun))listener;

@end


@interface LxTaskRegister : NSObject

- (void)regDataType:(int16_t)dataType executor:(LxTaskExecutor)executor cancelListener:(LxTaskCancelListener)cancelListener;

- (void)regStorage:(id<LxTaskStorage>)storage;

- (void)regRequisition:(id<LxTaskRequisition>)requisition;

- (void)regMaxRetryCount:(NSInteger)retryCount;

@end
