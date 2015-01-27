//
//  LxTaskQueue.h
//  LxTaskQueue
//
//  Created by lixin on 1/26/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LxTaskRegister.h"

@interface LxTaskQueue : NSObject

- (instancetype)initWithRegister:(LxTaskRegister*)reg;

- (void)enqueueTask:(LxTask*)task;

@end
