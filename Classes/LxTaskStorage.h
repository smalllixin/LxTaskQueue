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

- (BOOL)enqueueTask:(LxTask*)task toGroup:(NSString*)group;

- (void)dequeueTaskFromGroup:(NSString*)group;

- (NSSet*)availableGroups;

@end
