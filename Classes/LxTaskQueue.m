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
@property (nonatomic, strong) NSDictionary *taskExecutorMap;
@property (nonatomic, strong) id<LxTaskStorage> storage;
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@property (nonatomic, strong) id<LxTaskRequisition> requisition;
@end

@implementation LxTaskQueue

- (instancetype)initWithRegister:(LxTaskRegister*)reg {
    if ((self = [super init]) && self == nil)
        return nil;
    
    _taskExecutorMap = [reg executorMap];//immutable baby
    _storage = [reg storage];
    _requisition = [reg requisition];
    
    _taskQueue = dispatch_queue_create("lxtaskqueue", DISPATCH_QUEUE_SERIAL);
    
    __weak typeof(self) wself = self;
    [_requisition taskRunnableStatusChange:^(BOOL couldRun) {
        [wself envChanged:couldRun];
    }];
    return self;
}

- (void)envChanged:(BOOL)couldRun {
    
}

- (void)enqueueTask:(LxTask*)task {
    
}

@end
