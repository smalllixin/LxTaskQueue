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
@property (nonatomic, strong) id<LxTaskStorage> storage;
@property (nonatomic, strong) id<LxTaskRequisition> requisition;

@end

@implementation LxTaskRegister

- (id)init {
    if (self = [super init]) {
        _executorMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)regDataType:(int16_t)dataType executor:(LxTaskExecutor)executor {
    _executorMap[@(dataType)] = [executor copy];
}

- (void)regStorage:(id<LxTaskStorage>)storage {
    _storage = storage;
}

- (void)regRequisition:(id<LxTaskRequisition>)requisition {
    _requisition = requisition;
}

- (NSDictionary*)executorMap {
    return [[NSDictionary alloc] initWithDictionary:_executorMap];
}

- (id<LxTaskStorage>)storage {
    return _storage;
}

- (id<LxTaskRequisition>)requisition {
    return _requisition;
}

@end
