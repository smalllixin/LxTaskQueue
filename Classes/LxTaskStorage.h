//
//  LxTaskStorage.h
//  LxTaskQueue
//
//  Created by lixin on 1/27/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LxTask.h"

@protocol LxTaskStorage <NSObject>

- (BOOL)enqueueTask:(LxTask*)task;

- (void)replaceQueueHead:(LxTask*)task;

- (LxTask*)dequeueTaskFromGroup:(NSString*)group;

- (LxTask*)topTaskFromGroup:(NSString*)group;

- (NSArray*)removeAllTasksInGroup:(NSString*)group;

- (NSSet*)availableGroups;

@end
