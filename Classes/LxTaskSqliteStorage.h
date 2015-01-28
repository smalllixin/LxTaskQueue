//
//  LxTaskSqliteStorage.h
//  LxTaskQueue
//
//  Created by lixin on 1/28/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LxTaskStorage.h"

@interface LxTaskSqliteStorage : NSObject<LxTaskStorage>

- (instancetype)initWithDbName:(NSString*)dbName;

- (NSInteger)taskCountInGroup:(NSString*)group;

- (NSInteger)taskCount;

- (void)destoryDb;

@end
