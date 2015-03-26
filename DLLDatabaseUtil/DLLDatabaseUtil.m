//
//  DatabaseUtil.m
//  DatabaseUtil
//
//  Created by DLL on 14-5-29.
//  Copyright (c) 2014年 DLL. All rights reserved.
//

#import "DLLDatabaseUtil.h"

@implementation DLLDatabaseUtil


- (void)dealloc
{
    [_db release];
    [_dbPath release];
    [_lock release];
    [super dealloc];
}

+ (instancetype)sharedUtil
{
    static DLLDatabaseUtil *__databaseUtil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        __databaseUtil = [[DLLDatabaseUtil alloc] initWithFilePath:[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"database/database.sqlite"]];
    });
    return __databaseUtil;
}

- (NSString *)filePath
{
    return _dbPath;
}


- (instancetype)initWithFilePath:(NSString *)dbPath
{
    self = [super init];
    if (self) {
        _dbPath = [dbPath copy];
        [[NSFileManager defaultManager] createDirectoryAtPath:[_dbPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        _db = [[FMDatabase alloc] initWithPath:_dbPath];
        _db.crashOnErrors = NO;
        _lock = [[NSLock alloc] init];
        _isTransaction = NO;
    }
    return self;
}

- (BOOL) executeSQL:(NSString *)sql
{
    [self open];
    BOOL result = [_db executeUpdate:sql];
    [self close];
    return result;
}

- (long long)insertTalbe:(NSString *)tableName dataDictionary:(NSDictionary *)dictionary logErrors:(BOOL)logErrors
{
    long long result = -1;
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"insert into '%@' (", tableName];
    NSEnumerator *enumerator = [dictionary keyEnumerator];
    NSMutableArray *argArray = [[NSMutableArray alloc] init];
    for (NSString *key in enumerator) {
        [sql appendFormat:@"'%@',", key];
        [argArray addObject:[dictionary objectForKey:key]];
    }
    if (dictionary.count) {
        [sql deleteCharactersInRange:NSMakeRange(sql.length - 1, 1)];
    }
    [sql appendString:@") values ("];
    for (int i = 0; i < dictionary.count; i++) {
        [sql appendString:@"?,"];
    }
    if (dictionary.count) {
        [sql deleteCharactersInRange:NSMakeRange(sql.length - 1, 1)];
    }
    [sql appendString:@")"];
    _db.logsErrors = logErrors;
    [self open];
    if ([_db executeUpdate:sql withArgumentsInArray:argArray])
        result = [_db lastInsertRowId];
    [self close];
    _db.logsErrors = YES;
    [argArray release];
    [sql release];
    return result;
}

- (long long)insertTalbe:(NSString *)tableName dataDictionary:(NSDictionary *)dictionary
{
    return [self insertTalbe:tableName dataDictionary:dictionary logErrors:YES];
}

- (BOOL)updateTable:(NSString *)tableName dataDictionary:(NSDictionary *)dictionary withExtra:(NSString *)extra extraArg:(NSArray *)extraArg
{
    BOOL result = NO;
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"update \"%@\" set ", tableName];
    NSMutableArray *argArray = [[NSMutableArray alloc] init];
    NSEnumerator *keyEnumerator = [dictionary keyEnumerator];
    for (NSString *key in keyEnumerator)
    {
        [sql appendFormat:@"'%@'=?,", key];
        [argArray addObject:[dictionary objectForKey:key]];
    }
    if (dictionary.count) {
        [sql deleteCharactersInRange:NSMakeRange(sql.length - 1, 1)];
    }
    if (extra) {
        [sql appendFormat:@" %@", extra];
    }
    if (extraArg) {
        [argArray addObjectsFromArray:extraArg];
    }
    [self open];
    result = [_db executeUpdate:sql withArgumentsInArray:argArray];
    [self close];
    [argArray release];
    [sql release];
    return result;
}

- (FMDatabase *)database
{
    return _db;
}

- (BOOL)deleteTable:(NSString *)tableName withExtra:(NSString *)extra extraArg:(NSArray *)extraArg
{
    BOOL result = NO;
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"delete from \"%@\"", tableName];
    if (extra) {
        [sql appendFormat:@" %@", extra];
    }
    [self open];
    result = [_db executeUpdate:sql withArgumentsInArray:extraArg];
    [self close];
    [sql release];
    return result;
}

- (NSArray *)queryTable:(NSString *)tableName columns:(NSArray *)columns withExtra:(NSString *)extra extraArg:(NSArray *)extraArg
{
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"select %@ from \"%@\"", [self.class columnsNameFromArray:columns], tableName];
    if (extra) {
        [sql appendFormat:@" %@", extra];
    }
    [self open];
    FMResultSet *resultSet = [_db executeQuery:sql withArgumentsInArray:extraArg];
    NSArray *result = [self.class arrayFromResultSet:resultSet];
    [resultSet close];
    [self close];
    [sql release];
    return result;
}

+ (NSString *)columnsNameFromArray:(NSArray *)columns
{
    if (!columns || columns.count == 0) {
        return @"*";
    } else {
        NSMutableString *columnNames = [[NSMutableString alloc] init];
        for (NSString *columnName in columns) {
            [columnNames appendFormat:@"\"%@\",", columnName];
        }
        if (columnNames.length) {
            [columnNames deleteCharactersInRange:NSMakeRange(columnNames.length - 1, 1)];
        }
        return [columnNames autorelease];
    }
}

+ (NSArray *)arrayFromResultSet:(FMResultSet *)resultSet
{
    NSMutableArray *result = [NSMutableArray array];
    while ([resultSet next]) {
        [result addObject:[resultSet resultDictionary]];
    }
    return result;
}

- (NSArray *)executeQuery:(NSString *)sql
{
    [self open];
    NSArray *result = [self.class arrayFromResultSet:[_db executeQuery:sql]];
    [self close];
    return result;
}

- (NSArray *)executeQuery:(NSString *)sql extraArg:(NSArray *)extraArg
{
    [self open];
    NSArray *result = [self.class arrayFromResultSet:[_db executeQuery:sql withArgumentsInArray:extraArg]];
    [self close];
    return result;
}

- (BOOL) beginTransaction
{
    [self open];
    _isTransaction = [_db beginTransaction];
    return _isTransaction;
}

- (void) open
{
    if (!_isTransaction) {
        [_lock lock];
        [_db open];
    }
}

- (void)close
{
    if (!_isTransaction) {
        [_lock unlock];
        [_db close];
    }
}

- (BOOL) commit
{
    BOOL result = [_db commit];
    _isTransaction = NO;
    [self close];
    return result;
}

- (BOOL) rollBack
{
    [self open];
    BOOL result = [_db rollback];
    [self close];
    return result;
}
@end
