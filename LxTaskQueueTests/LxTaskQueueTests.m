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
#import "LxTaskMemStorage.h"
#import "LxTaskSqliteStorage.h"

typedef NS_ENUM(NSUInteger, TestTaskType) {
    kTestTaskTypeSimple,
};

@interface LxTaskQueueTests : XCTestCase<LxTaskRequisition>

@property (nonatomic, strong) LxTaskQueue *taskQueue;
@property (nonatomic, strong) LxTaskRegister *reg;
//@property (nonatomic, strong) LxTaskMemStorage *storage;
@property (nonatomic, strong) LxTaskSqliteStorage *storage;

@property (nonatomic, assign) BOOL isRunnable;
@end

@implementation LxTaskQueueTests

- (void)setUp {
    [super setUp];
//    self.storage = [LxTaskMemStorage new];
    self.storage = [[LxTaskSqliteStorage alloc] initWithDbName:@"test"];
    self.reg = [[LxTaskRegister alloc] init];
    [self.reg regRequisition:self];
    [self.reg regStorage:self.storage];
    [self.reg regMaxRetryCount:10];
    _isRunnable = YES;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _isRunnable = NO;
    [self.taskQueue syncQueueStopped];
    [self.taskQueue runBlockSync:^{
        [self.storage destoryDb];
    }];
    [super tearDown];
}

- (void)testExecuteSingleTaskCalled {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testExecuteSimpleTask"];
    
    void (^simpleTaskExecutor)(LxTask *task, LxTaskCompleteMarker completeMaker) = ^void(LxTask *task, LxTaskCompleteMarker completeMaker) {
        XCTAssertNotNil(task.data);
        completeMaker(task, LxTaskCompleteResultOk);
        [expectation fulfill];
    };
    
    [self.reg regDataType:kTestTaskTypeSimple executor:simpleTaskExecutor cancelListener:nil];
    self.taskQueue = [[LxTaskQueue alloc] initWithRegister:self.reg];
    
    
    NSDictionary *data = @{};
    LxTask *task = [[LxTask alloc] initWithType:kTestTaskTypeSimple data:data group:@"test" continueIfNotSuccess:NO];
    [self.taskQueue enqueueTask:task];
    
    [self waitForExpectationsWithTimeout:2.0f handler:^(NSError *error) {
        if(error)
        {
            NSLog(@"error is: %@", [error localizedDescription]);
        }
    }];
}

- (void)testExecuteManyTests {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testExecute10Tests"];
    int totalTask = 100;
    __block int counter = 0;
    void (^simpleTaskExecutor)(LxTask *task, LxTaskCompleteMarker completeMaker) = ^void(LxTask *task, LxTaskCompleteMarker completeMaker) {
        completeMaker(task, LxTaskCompleteResultOk);
        counter ++;
        if (counter == totalTask) {
            [expectation fulfill];
        }
    };
    
    [self.reg regDataType:kTestTaskTypeSimple executor:simpleTaskExecutor cancelListener:nil];
    self.taskQueue = [[LxTaskQueue alloc] initWithRegister:self.reg];
    
    NSDictionary *data = @{};
    for (int i = 0; i < totalTask; i ++) {
        NSString *group = [NSString stringWithFormat:@"%d", i%2];
        LxTask *task = [[LxTask alloc] initWithType:kTestTaskTypeSimple data:data group:group continueIfNotSuccess:NO];
        [self.taskQueue enqueueTask:task];
    }
    
    [self waitForExpectationsWithTimeout:2.0f handler:^(NSError *error) {
        if(error)
        {
            NSLog(@"error is: %@", [error localizedDescription]);
        }
    }];
}

- (void)testAsyncCompleteTest {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testAsyncCompleteTest"];
    
    void (^simpleTaskExecutor)(LxTask *task, LxTaskCompleteMarker completeMaker) = ^void(LxTask *task, LxTaskCompleteMarker completeMaker) {
        XCTAssertEqual([self.storage taskCount], 1);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completeMaker(task, LxTaskCompleteResultOk);
            [self.taskQueue runBlockInQueue:^{
                XCTAssertEqual([self.storage taskCount], 0);
                [expectation fulfill];
            }];
        });
    };
    
    [self.reg regDataType:kTestTaskTypeSimple executor:simpleTaskExecutor cancelListener:nil];
    self.taskQueue = [[LxTaskQueue alloc] initWithRegister:self.reg];
    
    
    NSDictionary *data = @{};
    LxTask *task = [[LxTask alloc] initWithType:kTestTaskTypeSimple data:data group:@"test" continueIfNotSuccess:NO];
    [self.taskQueue enqueueTask:task];
    
    [self waitForExpectationsWithTimeout:2.0f handler:^(NSError *error) {
        if(error)
        {
            NSLog(@"error is: %@", [error localizedDescription]);
        }
    }];
}

- (void)testTaskFailedTest {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testTaskFailedTest"];
    __block int counter = 0;
    void (^simpleTaskExecutor)(LxTask *task, LxTaskCompleteMarker completeMaker) = ^void(LxTask *task, LxTaskCompleteMarker completeMaker) {
        NSDictionary *d = (NSDictionary*)task.data;
        counter ++;
        NSInteger n = [d[@"id"] integerValue];
        if (n == 1) {
            
        } else {
            XCTAssert(NO);
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completeMaker(task, LxTaskCompleteResultFailed);
        });
    };
    
    __block int cancelCounter = 0;
    void (^cancelExecutor)(LxTask *task) = ^void(LxTask *task) {
        NSDictionary *d = (NSDictionary*)task.data;
        XCTAssertNotNil(d);
        cancelCounter ++;
        if (cancelCounter == 2 && [self.storage taskCount] == 0) {
            XCTAssertEqual(counter, 1);
            [expectation fulfill];
        }
    };
    
    [self.reg regDataType:kTestTaskTypeSimple executor:simpleTaskExecutor cancelListener:cancelExecutor];
    self.taskQueue = [[LxTaskQueue alloc] initWithRegister:self.reg];
    
    
    NSDictionary *data1 = @{@"id":@(1)};
    LxTask *task1 = [[LxTask alloc] initWithType:kTestTaskTypeSimple data:data1 group:@"test" continueIfNotSuccess:NO];
    [self.taskQueue enqueueTask:task1];
    
    NSDictionary *data2 = @{@"id":@(2)};
    LxTask *task2 = [[LxTask alloc] initWithType:kTestTaskTypeSimple data:data2 group:@"test" continueIfNotSuccess:NO];
    [self.taskQueue enqueueTask:task2];
    
    
    [self waitForExpectationsWithTimeout:2.0f handler:^(NSError *error) {
        if(error)
        {
            NSLog(@"error is: %@", [error localizedDescription]);
        }
    }];
}

- (void)testRetryTest {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRetryTest"];
    __block int counter = 0;
    __block int failedCounter = 0;
    void (^simpleTaskExecutor)(LxTask *task, LxTaskCompleteMarker completeMaker) = ^void(LxTask *task, LxTaskCompleteMarker completeMaker) {
        NSDictionary *d = (NSDictionary*)task.data;
        XCTAssertNotNil(d);
        if (failedCounter == 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                completeMaker(task, LxTaskCompleteResultNeedRetry);
            });
            failedCounter ++;
            return;
        }
        
        counter ++;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completeMaker(task, LxTaskCompleteResultOk);
            [self.taskQueue runBlockInQueue:^{
                if (counter == 2) {
                    XCTAssertEqual(failedCounter, 1);
                    [expectation fulfill];
                }
            }];
        });
    };
    
    void (^cancelExecutor)(LxTask *task) = ^void(LxTask *task) {
        XCTAssert(NO);
    };
    
    [self.reg regDataType:kTestTaskTypeSimple executor:simpleTaskExecutor cancelListener:cancelExecutor];
    self.taskQueue = [[LxTaskQueue alloc] initWithRegister:self.reg];
    
    
    NSDictionary *data1 = @{@"id":@(1)};
    LxTask *task1 = [[LxTask alloc] initWithType:kTestTaskTypeSimple data:data1 group:@"test" continueIfNotSuccess:NO];
    [self.taskQueue enqueueTask:task1];
    
    NSDictionary *data2 = @{@"id":@(2)};
    LxTask *task2 = [[LxTask alloc] initWithType:kTestTaskTypeSimple data:data2 group:@"test" continueIfNotSuccess:NO];
    [self.taskQueue enqueueTask:task2];
    
    
    [self waitForExpectationsWithTimeout:2.0f handler:^(NSError *error) {
        if(error)
        {
            NSLog(@"error is: %@", [error localizedDescription]);
        }
    }];
}

- (void)testRetryOutofTimesTest {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRetryOutofTimesTest"];
    __block int failedCounter = 0;
    void (^simpleTaskExecutor)(LxTask *task, LxTaskCompleteMarker completeMaker) = ^void(LxTask *task, LxTaskCompleteMarker completeMaker) {
        NSDictionary *d = (NSDictionary*)task.data;
        XCTAssertNotNil(d);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completeMaker(task, LxTaskCompleteResultNeedRetry);
        });
        failedCounter ++;
    };
    
    __block int cancelCounter = 0;
    void (^cancelExecutor)(LxTask *task) = ^void(LxTask *task) {
        cancelCounter ++;
        if (cancelCounter == 2) {
            [expectation fulfill];
        }
    };
    
    [self.reg regDataType:kTestTaskTypeSimple executor:simpleTaskExecutor cancelListener:cancelExecutor];
    self.taskQueue = [[LxTaskQueue alloc] initWithRegister:self.reg];
    
    
    NSDictionary *data1 = @{@"id":@(1)};
    LxTask *task1 = [[LxTask alloc] initWithType:kTestTaskTypeSimple data:data1 group:@"test" continueIfNotSuccess:NO];
    [self.taskQueue enqueueTask:task1];
    
    NSDictionary *data2 = @{@"id":@(2)};
    LxTask *task2 = [[LxTask alloc] initWithType:kTestTaskTypeSimple data:data2 group:@"test" continueIfNotSuccess:NO];
    [self.taskQueue enqueueTask:task2];
    
    
    [self waitForExpectationsWithTimeout:2.0f handler:^(NSError *error) {
        if(error)
        {
            NSLog(@"error is: %@", [error localizedDescription]);
        }
    }];
}

#pragma mark LxTaskRequisition
- (BOOL)isTaskRunnable {
    return _isRunnable;
}

- (void)taskRunnableStatusChange:(void(^)(BOOL couldRun))listener {
    
}

@end
