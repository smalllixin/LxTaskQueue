//
//  LxTaskMemStorage.m
//  LxTaskQueue
//
//  Created by lixin on 1/28/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import "LxTaskMemStorage.h"

@interface LxTaskMemStorage ()

@property (nonatomic, strong) NSMutableDictionary *store;

@end

@implementation LxTaskMemStorage

- (id)init {
    if (self = [super init]) {
        _store = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return self;
}

- (void)appendTask:(LxTask*)task {
    NSMutableArray *taskQueue = _store[task.group];
    if (!taskQueue) {
        taskQueue = [[NSMutableArray alloc] initWithCapacity:5];
        _store[task.group] = taskQueue;
    }
    [taskQueue addObject:task];
}

- (BOOL)enqueueTask:(LxTask*)task {
    [self appendTask:task];
    return YES;
}

- (void)replaceQueueHead:(LxTask*)task {
    NSMutableArray *taskQueue = _store[task.group];
    if (taskQueue && taskQueue.count > 0) {
        [taskQueue replaceObjectAtIndex:0 withObject:task];
    }
}

- (LxTask*)dequeueTaskFromGroup:(NSString*)group {
    NSMutableArray *taskQueue = _store[group];
    if (taskQueue && taskQueue.count > 0) {
        LxTask *task = taskQueue[0];
        [taskQueue removeObjectAtIndex:0];
        if (taskQueue.count == 0) {
            [_store removeObjectForKey:group];
        }
        return task;
    }
    return nil;
}

- (LxTask*)topTaskFromGroup:(NSString*)group {
    NSMutableArray *taskQueue = _store[group];
    if (taskQueue && taskQueue.count > 0) {
        return taskQueue[0];
    }
    return nil;
}

- (NSArray*)removeAllTasksInGroup:(NSString*)group {
    NSMutableArray *taskQueue = _store[group];
    if (taskQueue) {
        [_store removeObjectForKey:group];
    }
    return taskQueue;
}

- (NSSet*)availableGroups {
    return [NSSet setWithArray:[_store allKeys]];
}


#pragma mark - ForTest
- (NSInteger)taskCount {
    NSInteger count = 0;
    for (NSString *key in _store) {
        NSArray *t = _store[key];
        count += t.count;
    }
    return count;
}

- (NSInteger)taskCountInGroup:(NSString*)group {
    NSArray *a = _store[group];
    if (a) {
        return a.count;
    }
    return 0;
}

@end
