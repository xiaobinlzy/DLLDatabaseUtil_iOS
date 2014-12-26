//
//  DatabaseManager.m
//  Aibaotuan
//
//  Created by DLL on 14/12/26.
//  Copyright (c) 2014年 Aibaotuan. All rights reserved.
//

#import "DLLDatabaseHelper.h"




#define kDatabaseVersion @"database_version"
#define TABLE_PROPERTY @"property"


#define TABLE_CACHE @"infomation_cache"



@implementation DLLDatabaseHelper




- (instancetype)initWithDatabaseName:(NSString *)name andVersion:(NSInteger)version
{
    self = [self init];
    if (self) {
        _name = [name copy];
        _version = version;
        [self checkDatabase];
    }
    return self;
}


- (void)dealloc
{
    [_databaseUtil release];
    [super dealloc];
}


- (DLLDatabaseUtil *)database
{
    return _databaseUtil;
}


- (void)checkDatabase
{
    [_databaseUtil release];
    [_databaseUtil = [DLLDatabaseUtil alloc] initWithFilePath:[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:_name]];
    NSInteger dbVersion = 0;
    BOOL isFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[_databaseUtil filePath]];
    if (isFileExists) {
        dbVersion = [[self propertyForKey:kDatabaseVersion] integerValue];
    }
    if (dbVersion == _version && isFileExists) {
        return;
    }
    
    if (dbVersion == 0 || !isFileExists) {
        [self deleteDatabaseFile];
        if ([self createDatabase]) {
            [_databaseUtil executeSQL:@"create table if not exists 'property' ('key' text primary key, 'value' text)"];
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


- (BOOL)createDatabase
{
    return YES;
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
- (void)writeCache:(NSString *)info forType:(NSString *)type
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", info, @"info", [NSString stringWithFormat:@"%lld", (long long)[[NSDate date] timeIntervalSince1970]], @"time_line", nil];
    if ([_databaseUtil insertTalbe:TABLE_CACHE dataDictionary:dict logErrors:NO] < 0) {
        [_databaseUtil updateTable:TABLE_CACHE dataDictionary:dict withExtra:[NSString stringWithFormat:@"where \"type\"=\"%@\"", type] extraArg:nil];
    }
}

- (DatabaseCache *)cacheForType:(NSString *)type
{
    NSArray *resultArray = [_databaseUtil queryTable:TABLE_CACHE columns:nil withExtra:[NSString stringWithFormat:@"where \"type\"=\"%@\"", type] extraArg:nil];
    return resultArray.count > 0 ? [DatabaseCache cacheObjectWithDatabaseDictionary:[resultArray firstObject]] : nil;
}


- (void)deleteCacheType:(NSString *)type
{
    [_databaseUtil deleteTable:TABLE_CACHE withExtra:[NSString stringWithFormat:@"where \"type\"=\"%@\"", type] extraArg:nil];
}

@end


@implementation DatabaseCache

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

- (NSMutableDictionary *)JSONDictionary
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:self.type, @"type", self.info, @"info", [NSString stringWithFormat:@"%lld", (long long) self.timeLine], @"time_line", nil];
}



- (void)dealloc
{
    [_type release];
    [_info release];
    [super dealloc];
}

@end
