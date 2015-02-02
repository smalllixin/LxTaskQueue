//
//  LxTask.m
//  LxTaskQueue
//
//  Created by lixin on 1/27/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import "LxTask.h"

@interface LxTask()
@property (nonatomic, assign) NSInteger retriedCount;
@end

@implementation LxTask

- (instancetype)initWithType:(int16_t)executorType data:(id<NSCoding>)data group:(NSString*)group continueIfNotSuccess:(BOOL)continueIfNotSuccess {
    if (self = [super init]) {
        _type = executorType;
        _data = data;
        _group = group;
        _continueIfNotSuccess = continueIfNotSuccess;
        _retriedCount = 0;
    }
    return self;
}

- (instancetype)copyWithRetriedCount:(NSInteger)retriedCount {
    LxTask *newTask = [self copy];
    newTask.retriedCount = retriedCount;
    return newTask;
}

#pragma mark - Copy

- (id)copyWithZone:(NSZone *)zone {
    LxTask *object = [[LxTask alloc] initWithType:self.type data:self.data group:self.group continueIfNotSuccess:self.continueIfNotSuccess];
    object.prevTaskResult = self.prevTaskResult;
    return object;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _type = [aDecoder decodeIntForKey:@"type"];
        _data = [aDecoder decodeObjectForKey:@"data"];
        _prevTaskResult = [aDecoder decodeObjectForKey:@"prevTaskResult"];
        _group = [aDecoder decodeObjectForKey:@"group"];
        _continueIfNotSuccess = [aDecoder decodeBoolForKey:@"continueIfNotSuccess"];
        _retriedCount = [aDecoder decodeIntegerForKey:@"retriedCount"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInt:_type forKey:@"type"];
    [aCoder encodeObject:_data forKey:@"data"];
    [aCoder encodeObject:_prevTaskResult forKey:@"prevTaskResult"];
    [aCoder encodeObject:_group forKey:@"group"];
    [aCoder encodeBool:_continueIfNotSuccess forKey:@"continueIfNotSuccess"];
    [aCoder encodeInteger:_retriedCount forKey:@"retriedCount"];
}

@end
