//
//  LxTask.m
//  LxTaskQueue
//
//  Created by lixin on 1/27/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import "LxTask.h"

@interface LxTask()

@property (nonatomic, assign) int16_t type;
@property (nonatomic, strong) id<NSCoding> data;
@property (nonatomic, strong) NSString *group;
@end

@implementation LxTask

- (instancetype)initWithType:(int16_t)executorType data:(id<NSCoding>)data group:(NSString*)group {
    if (self = [super init]) {
        _type = executorType;
        _data = data;
        _group = group;
    }
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _type = [aDecoder decodeIntForKey:@"type"];
        _data = [aDecoder decodeObjectForKey:@"data"];
        _group = [aDecoder decodeObjectForKey:@"group"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInt:_type forKey:@"type"];
    [aCoder encodeObject:_data forKey:@"data"];
    [aCoder encodeObject:_group forKey:@"group"];
}

@end
