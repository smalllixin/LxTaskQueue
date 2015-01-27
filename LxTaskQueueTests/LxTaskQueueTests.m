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

@interface SimpleTestStorage:NSObject<LxTaskStorage>

@property (nonatomic, strong) NSMutableDictionary *store;

@end

@implementation SimpleTestStorage

- (id)init {
    if (self = [super init]) {
        _store = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return self;
}

- (void)appendTask:(LxTask*)task {
    NSMutableArray *taskQueue = _store[task.group];
    if (!taskQueue) {
        taskQueue = [[NSMutableArray alloc] initWithCapacity:5];
        _store[task.group] = taskQueue;
    }
    [taskQueue addObject:task];
}

- (BOOL)enqueueTask:(LxTask*)task {
    [self appendTask:task];
    return YES;
}

- (void)replaceQueueHead:(LxTask*)task {
    NSMutableArray *taskQueue = _store[task.group];
    if (taskQueue && taskQueue.count > 0) {
        [taskQueue replaceObjectAtIndex:0 withObject:task];
    }
}

- (LxTask*)dequeueTaskFromGroup:(NSString*)group {
    NSMutableArray *taskQueue = _store[group];
    if (taskQueue && taskQueue.count > 0) {
        LxTask *task = taskQueue[0];
        [taskQueue removeObjectAtIndex:0];
        return task;
    }
    return nil;
}

- (LxTask*)topTaskFromGroup:(NSString*)group {
    NSMutableArray *taskQueue = _store[group];
    if (taskQueue && taskQueue.count > 0) {
        return taskQueue[0];
    }
    return nil;
}

- (NSArray*)removeAllTasksInGroup:(NSString*)group {
    NSMutableArray *taskQueue = _store[group];
    if (taskQueue) {
        [_store removeObjectForKey:group];
    }
    return taskQueue;
}

- (NSSet*)availableGroups {
    return [NSSet setWithArray:[_store allKeys]];
}


#pragma mark - ForTest
- (NSInteger)taskCount {
    NSInteger count = 0;
    for (NSString *key in _store) {
        NSArray *t = _store[key];
        count += t.count;
    }
    return count;
}

@end

@interface LxTaskQueueTests : XCTestCase<LxTaskRequisition>

@property (nonatomic, strong) LxTaskQueue *taskQueue;
@property (nonatomic, strong) LxTaskRegister *reg;
@property (nonatomic, strong) SimpleTestStorage *storage;
@end

@implementation LxTaskQueueTests

- (void)setUp {
    [super setUp];
    self.storage = [SimpleTestStorage new];
    self.reg = [[LxTaskRegister alloc] init];
    [self.reg regRequisition:self];
    [self.reg regStorage:self.storage];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExecuteSingleTaskCalled {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testExecuteSimpleTask"];
    
    void (^simpleTaskExecutor)(LxTask *task, LxTaskCompleteMarker completeMaker) = ^void(LxTask *task, LxTaskCompleteMarker completeMaker) {
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
        LxTask *task = [[LxTask alloc] initWithType:kTestTaskTypeSimple data:data group:@"test" continueIfNotSuccess:NO];
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
            XCTAssertEqual([self.storage taskCount], 0);
            [expectation fulfill];
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

#pragma mark LxTaskRequisition
- (BOOL)isTaskRunnable {
    return YES;
}

- (void)taskRunnableStatusChange:(void(^)(BOOL couldRun))listener {
    
}

@end
