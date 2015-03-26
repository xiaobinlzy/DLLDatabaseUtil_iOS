//
//  DatabaseUtil.h
//  DatabaseUtil
//
//  Created by DLL on 14-5-29.
//  Copyright (c) 2014年 DLL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface DLLDatabaseUtil : NSObject {
    FMDatabase *_db;
    NSString *_dbPath;
    NSLock *_lock;
    BOOL _isTransaction;
}

/**
 获取默认单例
 **/
+ (instancetype) sharedUtil;


/**
 获取数据库文件路径
 **/
- (NSString *)filePath;

/**
 初始化数据库，参数传入文件路径，返回是否成功。
 **/
- (instancetype) initWithFilePath:(NSString *)dbPath;

/**
 执行写入SQL，返回是否成功。
 **/
- (BOOL) executeSQL:(NSString *)sql;

/**
 向数据库中插入记录，返回插入ID。若插入失败则返回-1
 **/
- (long long) insertTalbe:(NSString*)tableName dataDictionary:(NSDictionary*)dictionary;

/**
 向数据库中插入记录，返回插入ID。若插入失败则返回-1。参数logErrors决定是否显示错误日志。
 **/
- (long long) insertTalbe:(NSString *)tableName dataDictionary:(NSDictionary *)dictionary logErrors:(BOOL)logErrors;
/**
 update语句更新数据，返回是否成功。
 **/
- (BOOL) updateTable:(NSString*)tableName dataDictionary:(NSDictionary*)dictionary withExtra:(NSString*)extra extraArg:(NSArray*)extraArg;

/**
 delete语句删除数据，返回是否成功。
 **/
- (BOOL) deleteTable:(NSString *)tableName withExtra:(NSString *)extra extraArg:(NSArray *)extraArg;

/**
 单表查询，返回查询结果。
 **/
- (NSArray *) queryTable:(NSString *)tableName columns:(NSArray *)columns withExtra:(NSString *)extra extraArg:(NSArray *)extraArg;

/**
 执行查询语句，返回查询结果。
 **/
- (NSArray *) executeQuery:(NSString *)sql;

/**
 执行查询语句，可以带参数，返回查询结果。
 **/
- (NSArray *)executeQuery:(NSString *)sql extraArg:(NSArray *)extraArg;

/**
 开始事务
 **/
- (BOOL) beginTransaction;

/**
 提交事务
 **/
- (BOOL) commit;

/**
 回滚事务
 **/
- (BOOL) rollBack;

/**
 从结果集中获取数组
 **/
+ (NSArray *)arrayFromResultSet:(FMResultSet *)resultSet;
@end
