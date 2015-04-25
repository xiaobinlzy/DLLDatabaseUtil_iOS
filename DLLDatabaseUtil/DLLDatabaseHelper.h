//
//  DatabaseManager.h
//  Aibaotuan
//
//  Created by DLL on 14/12/26.
//  Copyright (c) 2014年 Aibaotuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLLDatabaseUtil.h"

@class DLLDatabaseCache;

@interface DLLDatabaseHelper : NSObject {
    DLLDatabaseUtil *_databaseUtil;
    NSString *_dbName;
    NSInteger _version;
    NSString *_dbFileName;
}

- (instancetype)initWithDatabaseName:(NSString *)name fileName:(NSString *)fileName andVersion:(NSUInteger)version;


- (void)checkDatabase;

- (void)deleteDatabaseFile;



- (DLLDatabaseUtil *)database;

/**
 当检测到没有数据库，需要重新创建的时候自动调用，子类需重写此方法
 */
- (BOOL)createDatabase;

/**
 子类重写此方法，当检测到数据库版本过低时会自动调用，返回是否升级成功。
 */
- (BOOL)updateDatabaseFromVersion:(NSUInteger)fromVersion;


#pragma mark - cache
- (void)setCache:(NSString *)info forType:(NSString *)type;
- (DLLDatabaseCache *)cacheForType:(NSString *)type;
- (void)deleteCacheType:(NSString *)type;
- (void)clearCacheBeforeDate:(NSTimeInterval)date;
@end




@interface DLLDatabaseCache : NSObject


@property (nonatomic, retain) NSString *type;

@property (nonatomic, retain) NSString *info;

@property (nonatomic, assign) NSTimeInterval timeLine;


+ (instancetype)cacheObjectWithDatabaseDictionary:(NSDictionary *)dict;

@end