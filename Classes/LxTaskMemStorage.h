//
//  LxTaskMemStorage.h
//  LxTaskQueue
//
//  Created by lixin on 1/28/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LxTaskStorage.h"

@interface LxTaskMemStorage : NSObject<LxTaskStorage>

- (NSInteger)taskCount;
- (NSInteger)taskCountInGroup:(NSString*)group;

@end
