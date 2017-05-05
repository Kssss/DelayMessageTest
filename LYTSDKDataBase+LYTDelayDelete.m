//
//  LYTDatabaseAPI+LYTDelayDelete.m
//  Antenna
//
//  Created by Vieene on 2016/12/9.
//  Copyright © 2016年 HHLY. All rights reserved.
//

#import "LYTSDKDataBase+LYTDelayDelete.h"
#import "LYTDelayDeleteTools.h"
@implementation LYTSDKDataBase (LYTDelayDelete)
- (void)createDelayDeleteTable
{
    
    dispatch_async(_concurrentQueue, ^{
        [self.dbQueue inDatabase:^(LYTDatabase *db) {
            BOOL result = [db executeUpdate:[NSString stringWithFormat:@"create table if not exists DelayDelete%@_table(messageKey text primary key not null,\
                                             delayDeleteInfo blob,\
                                             delayTime text,\
                                             deleteTime text);",@"xxx"]];
            NSAssert(result, @"创建DelayDelete表失败");
        }];
    });
}
- (void)cacheDelayDeleteInfo:(NSMutableDictionary *)dic
{
    NSLog(@"----%@",dic);
    
    dispatch_queue_t que = dispatch_queue_create("LYTDatabaseAPI+LYTDelayDelete", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(que, ^{
        [self.dbQueue inTransaction:^(LYTDatabase *db, BOOL *rollback) {
            //1、删除之前的数据
            NSString *sql = [NSString stringWithFormat:@"delete from DelayDelete%@_table;",@"xxx"];
            BOOL reult = [db executeUpdate:sql];
            if (!reult) {
                NSLog(@"删除延迟删除表失败，导致条目不存在");
            }
            //2、存储数据
            [dic enumerateKeysAndObjectsUsingBlock:^(NSString * key, LYTDelayDeleteInfo * value, BOOL * _Nonnull stop) {
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
                [db executeUpdate:[NSString stringWithFormat:@"insert or replace into DelayDelete%@_table (messageKey,delayDeleteInfo,delayTime,deleteTime) values( ?, ?, ?, ?)",@"xxx"],value.messageKey,data,@(value.delayTime),value.deleteTime];
            }];
        }];
    });
}
- (NSMutableDictionary *)getDelayDeleteInfo
{
    __block NSMutableDictionary *infoDic = [NSMutableDictionary dictionary];
    [self.dbQueue inTransaction:^(LYTDatabase *db, BOOL *rollback) {
        NSString *delaysql = [NSString stringWithFormat:@"SELECT * FROM DelayDelete%@_table;",@"xxx"];
        LYTResultSet *set  =  [db executeQuery:delaysql];
        while ([set next]) {
            NSData * data = [set dataForColumn:@"delayDeleteInfo"];
            LYTDelayDeleteInfo *info = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            NSString *messageKey = [set objectForColumnName:@"messageKey"];
            NSTimeInterval now = [[NSDate new] timeIntervalSince1970];
            NSTimeInterval old = [info.deleteTime doubleValue];
            if(now - old >= 0){
                info.delayTime = 0;
            }else{
                info.delayTime = old - now;
            }
            if (info) {
                [infoDic setObject:info forKey:messageKey];
            }
        }
        [set close];
    }];
    
    return infoDic;
}
@end
