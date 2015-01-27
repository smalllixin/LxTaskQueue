//
//  LxTaskQueueTests.m
//  LxTaskQueueTests
//
//  Created by lixin on 1/26/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LxTaskQueue.h"

typedef NS_ENUM(NSUInteger, TestTaskType) {
    kTestTaskTypeSimple,
};

@interface LxTaskQueueTests : XCTestCase

@property (nonatomic, strong) LxTaskQueue *taskQueue;
@end

@implementation LxTaskQueueTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExecuteSimpleTask {
    // This is an example of a functional test case.
    __block int executeCounter = 0;

    LxTaskRegister *reg = [[LxTaskRegister alloc] init];
    void (^simpleTaskExecutor)(id data) = ^void(id data) {
        executeCounter ++;
    };
    
    [reg regDataType:kTestTaskTypeSimple executor:simpleTaskExecutor];
    self.taskQueue = [[LxTaskQueue alloc] initWithRegister:reg];

    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
