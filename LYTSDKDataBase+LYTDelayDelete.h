//
//  LYTDatabaseAPI+LYTDelayDelete.h
//  Antenna
//
//  Created by Vieene on 2016/12/9.
//  Copyright © 2016年 HHLY. All rights reserved.
//

#import "LYTSDKDataBase.h"

@interface LYTSDKDataBase (LYTDelayDelete)

/**
 创建表
 */
- (void)createDelayDeleteTable;

/**
 缓存 阅后即焚 数据

 @param dic 存储阅后即焚相关信息
 */
- (void)cacheDelayDeleteInfo:(NSMutableDictionary *)dic;

/**
 获取 阅后即焚消息 字典
 */
- (NSMutableDictionary *)getDelayDeleteInfo;
@end
