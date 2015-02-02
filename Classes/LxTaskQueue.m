//
//  LxTaskQueue.m
//  LxTaskQueue
//
//  Created by lixin on 1/26/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import "LxTaskQueue.h"
#import "_LxTaskRegister.h"

@interface LxTaskQueue()

@property (nonatomic, strong) NSDictionary *taskExecutors;
@property (nonatomic, strong) NSDictionary *taskCancelListeners;
@property (nonatomic, strong) id<LxTaskStorage> storage;
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) id<LxTaskRequisition> requisition;
@property (nonatomic, assign) NSInteger maxRetryCount;
@property (nonatomic, strong) LxTask *executingTask;
@property (nonatomic, strong) NSObject *lock;

@property (nonatomic, strong) LxTask *runningTask;
@property (nonatomic, strong) void(^completeMarker)(LxTask *task, LxTaskCompleteResult result, id<NSCoding> dataPassing);
@end

@implementation LxTaskQueue

- (void)dealloc {
    
}

- (instancetype)initWithRegister:(LxTaskRegister*)reg {
    if ((self = [super init]) && self == nil)
        return nil;
    
    _lock = [NSObject new];
    
    _taskExecutors = [reg executorMap];//immutable baby
    _taskCancelListeners = [reg cancelListenerMap];
    
    _storage = [reg storage];
    _requisition = [reg requisition];
    _maxRetryCount = [reg maxRetryCount];
    
    _taskQueue = dispatch_queue_create("lxtaskqueue", DISPATCH_QUEUE_SERIAL);
    _serialQueue = dispatch_queue_create("lxserialqueue", DISPATCH_QUEUE_SERIAL);
    
    __weak typeof(self) wself = self;
    _completeMarker = [^void(LxTask *task, LxTaskCompleteResult result, id<NSCoding> dataPassing) {
        dispatch_async(wself.taskQueue, ^{
            @synchronized(wself.lock) {
                NSString *avoidGroup = nil;
                switch (result) {
                    case LxTaskCompleteResultNeedRetry: {
                        if (task.retriedCount > wself.maxRetryCount) {
                            for (LxTask *t in [wself.storage removeAllTasksInGroup:task.group]) {
                                [wself notifyTaskCancelled:t dataPassing:dataPassing];
                            }
                        } else {
                            avoidGroup = task.group;
                            LxTask *copiedTask = [task copyWithRetriedCount:task.retriedCount+1];
                            [wself.storage replaceQueueHead:copiedTask];
                        }
                    }
                        break;
                    case LxTaskCompleteResultFailed: {
                        if (task.continueIfNotSuccess) {
                            [wself.storage dequeueTaskFromGroup:task.group];
                            [wself notifyTaskCancelled:task dataPassing:dataPassing];
                        } else {
                            for (LxTask *t in [wself.storage removeAllTasksInGroup:task.group]) {
                                [wself notifyTaskCancelled:t dataPassing:dataPassing];
                            }
                        }
                    }
                        break;
                    case LxTaskCompleteResultOk:
                    default: {
                        [wself.storage dequeueTaskFromGroup:task.group];
                        LxTask *topTask = [wself.storage topTaskFromGroup:task.group];
                        if (topTask) {
                            topTask.prevTaskResult = dataPassing;
                            [wself.storage replaceQueueHead:topTask];
                        }
                    }
                        break;
                }
                wself.runningTask = nil;
                [wself fireAvoidGroup:avoidGroup];
            }
        });
    } copy];
    
    [_requisition taskRunnableStatusChange:^(BOOL couldRun) {
        if (couldRun) {
            [wself resumeIfStopped];
        }
    }];
    return self;
}

- (void)notifyTaskCancelled:(LxTask*)task dataPassing:(id<NSCoding>)dataPassing {
    LxTaskCancelListener cancelListener = _taskCancelListeners[@(task.type)];
    if (cancelListener) {
        task.prevTaskResult = dataPassing;
        cancelListener(task);
    }
}

- (void)resumeIfStopped {
    [self fireAvoidGroup:nil];
}

- (void)fireAvoidGroup:(NSString*)avoidGroup {
    dispatch_async(_taskQueue, ^{
        @synchronized(_lock) {
            if (_runningTask != nil) {
                return;
            }
        }
        if ([_requisition isTaskRunnable]) {
            NSSet *availableGroups;
            @synchronized(_lock) {
                availableGroups = [_storage availableGroups];
            };
            if (availableGroups.count > 0) {
                NSString *pickGroup = nil;
                if (avoidGroup) {
                    for (NSString *group in availableGroups) {
                        if (![group isEqualToString:avoidGroup]) {
                            pickGroup = group;
                        }
                    }
                    if (pickGroup == nil) {
                        pickGroup = [availableGroups anyObject];
                    }
                } else {
                    pickGroup = [availableGroups anyObject];
                }
                
                if (pickGroup == nil) {
                    //do not find any available group
                    return;
                }
                LxTask *task;
                @synchronized(_lock) {
                    task = [_storage topTaskFromGroup:pickGroup];
                }
                if (task) {
                    LxTaskExecutor executor = _taskExecutors[@(task.type)];
                    if (executor) {
                        @synchronized(_lock) {
                            _runningTask = task;
                        }
                        LxTaskCompleteMarker complete = ^void(LxTaskCompleteResult result, id<NSCoding> dataPassing) {
                            _completeMarker(task, result, dataPassing);
                        };
                        executor(task, complete);
                    } else {
                        NSLog(@"tasktype:%d not registered", task.type);
                        @synchronized(_lock) {
                            [_storage dequeueTaskFromGroup:task.group];
                        }
                    }
                }
            }
        }
    });
}

- (void)enqueueTask:(LxTask*)task {
    dispatch_async(_serialQueue, ^{
        @synchronized(_lock) {
            //persist first
            if (![_storage enqueueTask:task]) {
                NSLog(@"ERROR: Task storage enqueue failed.");
            }
        }
        [self resumeIfStopped];
    });
}

- (void)runBlockInQueue:(void(^)())block {
    dispatch_async(_taskQueue, block);
}

- (void)runBlockSync:(void(^)())block {
    @synchronized(self) {
        block();
    }
}

- (void)syncQueueStopped {
    dispatch_sync(_taskQueue, ^{
        
    });
}

@end
