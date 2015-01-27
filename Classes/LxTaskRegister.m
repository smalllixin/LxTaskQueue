//
//  LxTaskRegister.m
//  LxTaskQueue
//
//  Created by lixin on 1/27/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import "LxTaskRegister.h"

@interface LxTaskRegister()

@property (nonatomic, strong) NSMutableDictionary *executorMap;
@property (nonatomic, strong) NSMutableDictionary *cancelListenerMap;
@property (nonatomic, strong) id<LxTaskStorage> storage;
@property (nonatomic, strong) id<LxTaskRequisition> requisition;
@property (nonatomic, assign) NSInteger maxRetryCount;
@end

@implementation LxTaskRegister

- (id)init {
    if (self = [super init]) {
        _executorMap = [[NSMutableDictionary alloc] initWithCapacity:10];
        _cancelListenerMap = [[NSMutableDictionary alloc] initWithCapacity:10];
        _maxRetryCount = 5;
    }
    return self;
}

- (void)regDataType:(int16_t)dataType executor:(LxTaskExecutor)executor cancelListener:(LxTaskCancelListener)cancelListener {
    _executorMap[@(dataType)] = [executor copy];
    if (cancelListener) {
        _cancelListenerMap[@(dataType)] = [cancelListener copy];
    }
}

- (void)regStorage:(id<LxTaskStorage>)storage {
    _storage = storage;
}

- (void)regRequisition:(id<LxTaskRequisition>)requisition {
    _requisition = requisition;
}

- (void)regMaxRetryCount:(NSInteger)retryCount {
    _maxRetryCount = retryCount;
}


- (NSDictionary*)executorMap {
    return [[NSDictionary alloc] initWithDictionary:_executorMap];
}

- (NSDictionary*)cancelListenerMap {
    return [[NSDictionary alloc] initWithDictionary:_cancelListenerMap];
}

- (id<LxTaskStorage>)storage {
    return _storage;
}

- (id<LxTaskRequisition>)requisition {
    return _requisition;
}

- (NSInteger)maxRetryCount {
    return _maxRetryCount;
}

@end
