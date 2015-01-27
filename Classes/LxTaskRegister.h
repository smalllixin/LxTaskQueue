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

typedef void (^LxTaskExecutor)(id<NSCoding> data);

@interface LxTaskRegister : NSObject

- (void)regDataType:(int16_t)dataType executor:(LxTaskExecutor)executor;
- (void)regStorage:(id<LxTaskStorage>)storage;

@end
