//
//  DatabaseManager.m
//  Aibaotuan
//
//  Created by DLL on 14/12/26.
//  Copyright (c) 2014年 Aibaotuan. All rights reserved.
//

#import "DLLDatabaseHelper.h"




#define kDatabaseVersion @"dlldatabaseutil_database_version"
#define TABLE_PROPERTY @"dlldatabaseutil_property"


#define TABLE_CACHE @"dlldatabaseutil_infomation_cache"



@implementation DLLDatabaseHelper




- (instancetype)initWithDatabaseName:(NSString *)name fileName:(NSString *)fileName andVersion:(NSUInteger)version
{
    self = [self init];
    if (self) {
        _dbName = [name copy];
        _dbFileName = [fileName copy];
        _version = version;
        [self checkDatabase];
    }
    return self;
}


- (void)dealloc
{
    [_databaseUtil release];
    [_dbName release];
    [_dbFileName release];
    [super dealloc];
}


- (DLLDatabaseUtil *)database
{
    return _databaseUtil;
}


- (void)checkDatabase
{
    [_databaseUtil release];
    [_databaseUtil = [DLLDatabaseUtil alloc] initWithFilePath:[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", _dbName, _dbFileName]]];
    NSUInteger dbVersion = UINT32_MAX;
    BOOL isFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[_databaseUtil filePath]];
    if (isFileExists) {
        dbVersion = [[self propertyForKey:kDatabaseVersion] integerValue];
    }
    if (dbVersion == _version && isFileExists) {
        return;
    }
    
    if (dbVersion == UINT32_MAX || !isFileExists) {
        [self deleteDatabaseFile];
        if ([self createDatabase]) {
            [_databaseUtil executeSQL:[NSString stringWithFormat:@"create table if not exists '%@' ('key' text primary key, 'value' text)", TABLE_PROPERTY]];
            [self setProperty:[NSString stringWithFormat:@"%d", (int)_version] forKey:kDatabaseVersion];
        }
        return;
    }
    
    if (dbVersion < _version) {
        if ([self updateDatabaseFromVersion:dbVersion]) {
            [self setProperty:[NSString stringWithFormat:@"%d", (int)_version] forKey:kDatabaseVersion];
        }
        return;
    }
    
    
}


- (BOOL)createDatabase {
    BOOL result = YES;
    result &= [_databaseUtil executeSQL:[NSString stringWithFormat:@"create table if not exists '%@' ('type' text primary key, 'info' text, 'time_line' integer)", TABLE_CACHE]];
    result &= [_databaseUtil executeSQL:[NSString stringWithFormat:@"create index if not exists '%@_index' on '%@' ('type', 'time_line')", TABLE_CACHE, TABLE_CACHE]];
    return result;
}


- (BOOL)updateDatabaseFromVersion:(NSUInteger)fromVersion
{
    return YES;
}

- (void)deleteDatabaseFile
{
    [[NSFileManager defaultManager] removeItemAtPath:[_databaseUtil filePath] error:nil];
}

#pragma mark - database property
- (void)setProperty:(NSString *)value forKey:(NSString *)key
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:value, @"value", key, @"key", nil];
    if (![_databaseUtil insertTalbe:TABLE_PROPERTY dataDictionary:dict logErrors:NO]) {
        [_databaseUtil updateTable:TABLE_PROPERTY dataDictionary:dict withExtra:[NSString stringWithFormat:@"where \"key\"=\"%@\"", key] extraArg:nil];
    }
}


- (NSString *)propertyForKey:(NSString *)key
{
    NSArray *resultArray = [_databaseUtil queryTable:TABLE_PROPERTY columns:[NSArray arrayWithObject:@"value"] withExtra:[NSString stringWithFormat:@"where \"key\"=\"%@\"", key] extraArg:nil];
    return resultArray.count > 0 ? [[resultArray firstObject] objectForKey:@"value"] : nil;
}

#pragma mark - cache
- (void)setCache:(NSString *)info forType:(NSString *)type
{
    if (type.length > 0) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", info, @"info", [NSString stringWithFormat:@"%lld", (long long)[[NSDate date] timeIntervalSince1970]], @"time_line", nil];
        if ([_databaseUtil insertTalbe:TABLE_CACHE dataDictionary:dict logErrors:NO] < 0) {
            [_databaseUtil updateTable:TABLE_CACHE dataDictionary:dict withExtra:[NSString stringWithFormat:@"where \"type\"=\"%@\"", type] extraArg:nil];
        }
    }
}

- (DLLDatabaseCache *)cacheForType:(NSString *)type
{
    if (type.length > 0) {
        NSArray *resultArray = [_databaseUtil queryTable:TABLE_CACHE columns:nil withExtra:[NSString stringWithFormat:@"where \"type\"=\"%@\"", type] extraArg:nil];
        return resultArray.count > 0 ? [DLLDatabaseCache cacheObjectWithDatabaseDictionary:[resultArray firstObject]] : nil;
    }
    return nil;
}


- (void)deleteCacheType:(NSString *)type
{
    if (type.length > 0) {
        [_databaseUtil deleteTable:TABLE_CACHE withExtra:[NSString stringWithFormat:@"where \"type\"=\"%@\"", type] extraArg:nil];
    }
}

@end


@implementation DLLDatabaseCache

@synthesize type = _type;
@synthesize info = _info;
@synthesize timeLine = _timeLine;


+ (instancetype)cacheObjectWithDatabaseDictionary:(NSDictionary *)dict
{
    return [[[self alloc] initWithDatabaseDictionary:dict] autorelease];
}

- (instancetype)initWithDatabaseDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.type = [dictionary objectForKey:@"type"];
        self.info = [dictionary objectForKey:@"info"];
        self.timeLine = [[dictionary objectForKey:@"time_line"] doubleValue];
    }
    return self;
}




- (void)dealloc
{
    [_type release];
    [_info release];
    [super dealloc];
}

@end
