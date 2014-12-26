//
//  DatabaseManager.h
//  Aibaotuan
//
//  Created by DLL on 14/12/26.
//  Copyright (c) 2014年 Aibaotuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLLDatabaseUtil.h"


@interface DLLDatabaseHelper : NSObject {
    DLLDatabaseUtil *_databaseUtil;
    NSString *_name;
    NSInteger _version;
}

- (instancetype)initWithDatabaseName:(NSString *)name andVersion:(NSInteger)version;


- (void)checkDatabase;

- (void)deleteDatabaseFile;



- (DLLDatabaseUtil *)database;
- (BOOL)createDatabase;

- (BOOL)updateDatabaseFromVersion:(NSUInteger)fromVersion;

@end




@interface DatabaseCache : NSObject


@property (nonatomic, retain) NSString *type;

@property (nonatomic, retain) NSString *info;

@property (nonatomic, assign) NSTimeInterval timeLine;


+ (instancetype)cacheObjectWithDatabaseDictionary:(NSDictionary *)dict;

@end