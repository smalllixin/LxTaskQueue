//
//  LxTaskSqliteStorage.m
//  LxTaskQueue
//
//  Created by lixin on 1/28/15.
//  Copyright (c) 2015 lxtap. All rights reserved.
//

#import "LxTaskSqliteStorage.h"
#import <sqlite3.h>

@interface LxTaskSqliteStorage ()

@property (nonatomic, strong) NSString *dbName;

@end

@implementation LxTaskSqliteStorage
{
    sqlite3 *db;
}

- (void)dealloc {
    if (db) {
        sqlite3_close(db);
        db = NULL;
    }
}

#pragma mark Initialization
- (instancetype)initWithDbName:(NSString*)dbName {
    if (self = [super init]) {
        self.dbName = dbName;
        [self setup];
    }
    return self;
}

- (void)setup {
    NSString *dbpath = [self dbPath];
    if (sqlite3_open_v2([dbpath UTF8String], &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {
        NSString *errMsg = [NSString stringWithUTF8String:sqlite3_errmsg(db)];
        NSLog(@"%@", errMsg);
        NSAssert(NO, @"sqlite storage create failed");
    }
    
    const char *sql = "CREATE TABLE IF NOT EXISTS Tasks(\
                        id INTEGER PRIMARY KEY,\
                        type INTEGER NOT NULL,\
                        groupId TEXT NOT NULL,\
                        data BLOB,\
                        sortValue INTEGER\
                        )";
    char *errMsg;
    if (sqlite3_exec(db, sql, NULL, NULL, &errMsg) != SQLITE_OK) {
        NSLog(@"%@", [NSString stringWithUTF8String:errMsg]);
        NSAssert(NO, @"create table failed");
    }
    
    void (^createIdx)(const char* columnName) = ^(const char* columnName){
        char *errMsg;
        char idxsql[256];
        sprintf(idxsql, "CREATE INDEX IF NOT EXISTS %s_index ON Tasks (%s)", columnName, columnName);
        if (sqlite3_exec(db, idxsql, NULL, NULL, &errMsg) != SQLITE_OK) {
            NSLog(@"%@", [NSString stringWithUTF8String:errMsg]);
            NSAssert(NO, @"create index failed");
        }
    };
    
    createIdx("groupId");
    createIdx("sortValue");
}

#pragma mark Utils

- (NSString*)dbPath {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dbpath = [docPath stringByAppendingPathComponent:self.dbName];
    return dbpath;
}

#pragma mark - Public
- (void)destoryDb {
    if (db) {
        sqlite3_close(db);
        db = NULL;
        NSString *dbfile = [self dbPath];
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:dbfile] error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
    }
}

- (NSInteger)taskCount {
    const char *sql = "SELECT COUNT(*) FROM Tasks";
    sqlite3_stmt *stmt;
    int rc;
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    NSAssert(rc == SQLITE_OK, @"");
    rc = sqlite3_step(stmt);
    NSAssert(rc == SQLITE_ROW, @"");
    int count = sqlite3_column_int(stmt, 0);
    sqlite3_finalize(stmt);
    return count;
}

- (NSInteger)taskCountInGroup:(NSString*)group {
    const char *sql = "SELECT COUNT(*) FROM Tasks WHERE groupId=?";
    sqlite3_stmt *stmt;
    int rc;
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    NSAssert(rc == SQLITE_OK, @"");
    sqlite3_bind_text(stmt, 1, [group UTF8String], -1, SQLITE_STATIC);
    rc = sqlite3_step(stmt);
    NSAssert(rc == SQLITE_ROW, @"");
    int count = sqlite3_column_int(stmt, 0);
    sqlite3_finalize(stmt);
    return count;
}

#pragma mark Db Utils
- (int)nextSortValueInGroup:(NSString*)group {
    int sortValue = 0;
    const char *sql = "SELECT MAX(sortValue) FROM Tasks WHERE groupId=?";
    int rc;
    sqlite3_stmt *stmt;
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    NSAssert(rc == SQLITE_OK, @"");
    sqlite3_bind_text(stmt, 1, [group UTF8String], -1, SQLITE_STATIC);
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        sortValue = sqlite3_column_int(stmt, 0);
    }
    sqlite3_finalize(stmt);
    return sortValue + 1;
}

- (LxTask*)unarchiveTaskFromStmt:(sqlite3_stmt*)stmt atColumn:(int)column {
    int nBytes = sqlite3_column_bytes(stmt, column);
    void *buf = malloc(nBytes);
    memcpy(buf, sqlite3_column_blob(stmt, column), nBytes);
    NSData *archivedTask = [NSData dataWithBytesNoCopy:buf length:nBytes];
    LxTask *task = [NSKeyedUnarchiver unarchiveObjectWithData:archivedTask];
    archivedTask = nil;
    return task;
}

- (LxTask*)topTaskFromGroup:(NSString *)group objId:(int*)objId sortValue:(int*)sortValue {
    const char *sql = "SELECT id,data,sortValue FROM Tasks WHERE groupId=? ORDER BY sortValue ASC LIMIT 1";
    LxTask *task;
    int rc;
    sqlite3_stmt *stmt;
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    NSAssert(rc == SQLITE_OK, @"");
    sqlite3_bind_text(stmt, 1, [group UTF8String], -1, SQLITE_STATIC);
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        if (objId) {
            *objId = sqlite3_column_int(stmt, 0);
        }
        task = [self unarchiveTaskFromStmt:stmt atColumn:1];
        
        if (sortValue) {
            *sortValue = sqlite3_column_int(stmt, 2);
        }
    }
    sqlite3_finalize(stmt);
    return task;
}

- (void)deleteTaskById:(int)taskId {
    const char *sql = "DELETE FROM Tasks WHERE id=?";
    sqlite3_stmt *stmt;
    int rc;
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    NSAssert(rc==SQLITE_OK, @"");
    sqlite3_bind_int(stmt, 1, taskId);
    rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
}

- (BOOL)enqueueTask:(LxTask *)task withSortValue:(int)sortValue {
    const char *sql = "INSERT INTO Tasks(type, groupId, data, sortValue) VALUES(?,?,?,?)";
    int rc;
    sqlite3_stmt *stmt;
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        NSString *errMsg = [NSString stringWithUTF8String:sqlite3_errmsg(db)];
        NSLog(@"%@", errMsg);
        return NO;
    }
    NSData *archivedTask = [NSKeyedArchiver archivedDataWithRootObject:task];
    const void* data = [archivedTask bytes];
    NSUInteger dataLen = [archivedTask length];
    if (sortValue < 0) {
        int nextSortValue = [self nextSortValueInGroup:task.group];
        sortValue = nextSortValue;
    }
    sqlite3_bind_int(stmt, 1, task.type);
    sqlite3_bind_text(stmt, 2, [task.group UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_blob(stmt, 3, data, (int)dataLen, SQLITE_STATIC);
    sqlite3_bind_int(stmt, 4, sortValue);
    rc = sqlite3_step(stmt);
    NSAssert(rc==SQLITE_DONE, @"insert failed!");
    sqlite3_finalize(stmt);
    return YES;
}

#pragma mark LxTaskStorage Protocol

- (BOOL)enqueueTask:(LxTask*)task {
    return [self enqueueTask:task withSortValue:-1];
}

- (void)replaceQueueHead:(LxTask*)task {
    int objId;
    int sortValue;
    LxTask *currentTask = [self topTaskFromGroup:task.group objId:&objId sortValue:&sortValue];
    if (currentTask) {
        //delete & insert with same sortValue;
        [self deleteTaskById:objId];
        [self enqueueTask:task withSortValue:sortValue];
    } else {
        //insert normally
        [self enqueueTask:task];
    }
}

- (LxTask*)dequeueTaskFromGroup:(NSString*)group {
    int objId;
    LxTask *task = [self topTaskFromGroup:group objId:&objId sortValue:NULL];
    if (task) {
        const char *sql = "DELETE FROM Tasks WHERE id=?";
        sqlite3_stmt *stmt;
        int rc;
        rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
        NSAssert(rc==SQLITE_OK, @"");
        sqlite3_bind_int(stmt, 1, objId);
        rc = sqlite3_step(stmt);
        sqlite3_finalize(stmt);
    }
    return task;
}

- (LxTask*)topTaskFromGroup:(NSString*)group {
    return [self topTaskFromGroup:group objId:NULL sortValue:NULL];
}

- (NSArray*)removeAllTasksInGroup:(NSString*)group {
    const char *sql = "SELECT data FROM Tasks WHERE groupId=? ORDER BY sortValue ASC";
    sqlite3_stmt *stmt;
    int rc;
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    NSAssert(rc==SQLITE_OK, @"");
    sqlite3_bind_text(stmt, 1, [group UTF8String], -1, SQLITE_STATIC);
    NSMutableArray *tasks = [[NSMutableArray alloc] initWithCapacity:10];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        [tasks addObject:[self unarchiveTaskFromStmt:stmt atColumn:0]];
    }
    sqlite3_finalize(stmt);
    
    {
        const char *deleteSql = "DELETE FROM Tasks WHERE groupId=?";
        sqlite3_stmt *stmt;
        int rc;
        rc = sqlite3_prepare_v2(db, deleteSql, -1, &stmt, 0);
        NSAssert(rc==SQLITE_OK, @"");
        sqlite3_bind_text(stmt, 1, [group UTF8String], -1, SQLITE_STATIC);
        rc = sqlite3_step(stmt);
        NSAssert(rc==SQLITE_DONE, @"");
    }
    return tasks;
}

- (NSSet*)availableGroups {
    const char *sql = "SELECT DISTINCT groupId FROM Tasks";//SELECT groupId FROM Tasks GROUP BY groupId
    sqlite3_stmt *stmt;
    int rc;
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    NSAssert(rc==SQLITE_OK, @"");
    NSMutableArray *groups = [[NSMutableArray alloc] initWithCapacity:10];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        char *groupId = (char *)sqlite3_column_text(stmt, 0);
        [groups addObject:[NSString stringWithUTF8String:groupId]];
    }
    sqlite3_finalize(stmt);
    return [NSSet setWithArray:groups];
}

@end
