//
//  TaskSqliteStorageTest.m
//  LxTaskQueue
//
//  Created by lixin on 1/28/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LxTaskSqliteStorage.h"

@interface TaskSqliteStorageTest : XCTestCase

@property (nonatomic, strong) LxTaskSqliteStorage *db;
@end

@implementation TaskSqliteStorageTest

- (void)setUp {
    [super setUp];
    _db = [[LxTaskSqliteStorage alloc] initWithDbName:@"test.db"];
}

- (void)tearDown {
    [super tearDown];
    [_db destoryDb];
}

- (void)testEnqueue {
    LxTask *task = [[LxTask alloc] initWithType:1 data:@{@"id":@(1)} group:@"test" continueIfNotSuccess:YES];
    [_db enqueueTask:task];
    LxTask *taskTop = [_db topTaskFromGroup:@"test"];
    XCTAssertEqual(taskTop.type, 1);
    XCTAssertEqualObjects(taskTop.group, @"test");
    NSDictionary *d = (NSDictionary*)taskTop.data;
    XCTAssertEqual([d[@"id"] integerValue], 1);
}

- (void)testDequeue {
    LxTask *task1 = [[LxTask alloc] initWithType:1 data:@{@"id":@(1)} group:@"test" continueIfNotSuccess:YES];
    LxTask *task2 = [[LxTask alloc] initWithType:2 data:@{@"id":@(2)} group:@"test" continueIfNotSuccess:YES];
    LxTask *task3 = [[LxTask alloc] initWithType:3 data:@{@"id":@(3)} group:@"test" continueIfNotSuccess:YES];
    [_db enqueueTask:task1];
    [_db enqueueTask:task2];
    [_db enqueueTask:task3];
    
    XCTAssertNil([_db dequeueTaskFromGroup:@"notexist"]);
    
    LxTask *dTask1 = [_db dequeueTaskFromGroup:@"test"];
    LxTask *dTask2 = [_db dequeueTaskFromGroup:@"test"];
    LxTask *dTask3 = [_db dequeueTaskFromGroup:@"test"];
    
    XCTAssertEqual(dTask1.type, 1);
    XCTAssertEqualObjects(dTask1.group, @"test");
    NSDictionary *d1 = (NSDictionary*)dTask1.data;
    XCTAssertEqual([d1[@"id"] integerValue], 1);
    
    XCTAssertEqual(dTask2.type, 2);
    XCTAssertEqualObjects(dTask2.group, @"test");
    NSDictionary *d2 = (NSDictionary*)dTask2.data;
    XCTAssertEqual([d2[@"id"] integerValue], 2);
    
    XCTAssertEqual(dTask3.type, 3);
    XCTAssertEqualObjects(dTask3.group, @"test");
    NSDictionary *d3 = (NSDictionary*)dTask3.data;
    XCTAssertEqual([d3[@"id"] integerValue], 3);
}

@end
