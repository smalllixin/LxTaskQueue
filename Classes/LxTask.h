//
//  LxTask.h
//  LxTaskQueue
//
//  Created by lixin on 1/27/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LxTask : NSObject<NSCoding>

- (instancetype)initWithType:(int16_t)executorType data:(id<NSCoding>)data group:(NSString*)group;

@property (nonatomic, assign, readonly) int16_t type;
@property (nonatomic, strong, readonly) id<NSCoding> data;
@property (nonatomic, strong, readonly) NSString *group;

@end
