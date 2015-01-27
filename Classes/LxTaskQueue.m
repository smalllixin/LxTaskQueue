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
@end

@implementation LxTaskQueue

- (instancetype)initWithRegister:(LxTaskRegister*)reg {
    if ((self = [super init]) && self == nil)
        return nil;
    
    _taskExecutorMap = [reg executorMap];//immutable baby
    return self;
}

@end
