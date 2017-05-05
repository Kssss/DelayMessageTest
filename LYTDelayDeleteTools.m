//
//  CJDelayDeleteTools.m
//  Antenna
//
//  Created by Vieene on 2016/12/9.
//  Copyright © 2016年 HHLY. All rights reserved.
//

#import "LYTDelayDeleteTools.h"
#import "LYTMessage.h"
//#import "LYTSDKHeader.h"
#import "LYTSDKDataBase+LYTDelayDelete.h"
//#import "LYTSDKDataBase+LYTMessage.h"

@interface LYTDelayDeleteTools ()
@property (nonatomic,strong) NSMutableDictionary *sessionDic;
// key and  time 
@property (nonatomic,strong) NSMutableDictionary *postDic;
@property (nonatomic,strong) NSTimer *timer;
@end
@implementation LYTDelayDeleteTools
static LYTDelayDeleteTools *tools = nil;
+ (instancetype)sharedTools
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tools = [[LYTDelayDeleteTools alloc] init];
    });
    return tools;
}
- (instancetype)init
{
    if (self = [super init]) {
        _sessionDic = [NSMutableDictionary dictionary];
        _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(deleteTimer:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cacheDelayToolsTimeToLocal) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getlocalCacheInfo) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}
//加入 阅后即焚的模型 到计时器 进行计时
- (void)addDelayMessage:(LYTMessage *)message succeed:(void (^)(BOOL))block
{
    NSAssert(message.targetId, @"targetID 不能为空");
    NSString *key = [self messagekeyWithMessage:message];
    
    //检查重复,避免重复加入到阅后即焚缓存列表
    if ([self checkExist:key]) return ;
    
    LYTDelayDeleteInfo *info = [[LYTDelayDeleteInfo alloc] init];
    info.delayTime = message.delayDeleteTime;
    info.targetId = message.targetId;
    info.message = message;
    info.deleteTime = [[NSString stringWithFormat:@"%f", ([[NSDate new] timeIntervalSince1970] + info.delayTime)] substringToIndex:10];//换成秒
    info.messageKey = key;
    [self.sessionDic setObject:info forKey:info.messageKey];
    block(YES);
}
- (BOOL)checkExist:(NSString *)key
{
    if ([[self.sessionDic allKeys] containsObject:key]) {
        return YES;
    }
    return NO;
}
- (NSString *)messagekeyWithMessage:(LYTMessage *)message
{
    return [NSString stringWithFormat:@"%@##%ld",message.targetId,(long)message.messageId];
}
//根据查询当前 阅后即焚消息,最新的计时时间)
- (NSInteger)quaryDelayTimeForMessage:(LYTMessage *)message
{
    if ([[self.sessionDic allKeys] containsObject:[self messagekeyWithMessage:message]]) {
        LYTDelayDeleteInfo *info = self.sessionDic[[self messagekeyWithMessage:message]];
        SDKLog(@"--------%zd",info.delayTime);
        return info.delayTime;
    }
    NSAssert(NO, @"出现错误,阅后即焚消息应该需要有初始阅后即焚的时间！");
    return 20;
}
- (void)refreshDataSource
{
    self.postDic = [NSMutableDictionary dictionary];
   [self.sessionDic enumerateKeysAndObjectsUsingBlock:^(NSString * key, LYTDelayDeleteInfo  * obj, BOOL * _Nonnull stop) {
       obj.delayTime --;
       [self.postDic setObject:[NSString stringWithFormat:@"%zd",obj.delayTime] forKey:key];
       if (obj.delayTime <= 0) {
           //1、说明应该删除
           if([self.delayDeleteDelegate respondsToSelector:@selector(willDeleteData:)]){
               [self.delayDeleteDelegate willDeleteData:obj.message];
           }
           //2、删除本地数据库的消息
           [self delelteSessionFromDataBase:obj];
           //3、从阅后即焚内存缓存中删除记录
           [self.sessionDic removeObjectForKey:obj.messageKey];
       }
   }];
}

//更新本工具数据库的时间(程序后台的时候保存）
- (void)cacheDelayToolsTimeToLocal
{
    [[LYTSDKDataBase shareDatabase] cacheDelayDeleteInfo:self.sessionDic];
}

/**
 获取存储在本地的阅后即焚消息计时数据（每次APP进入前台初始化需要使用）
 */
- (void )getlocalCacheInfo
{
    [LYTDelayDeleteTools sharedTools].sessionDic =  [[[LYTSDKDataBase shareDatabase] getDelayDeleteInfo] mutableCopy];
    SDKLog(@"%@",[LYTDelayDeleteTools sharedTools].sessionDic);
}
- (void)dealloc
{
    [_timer invalidate];
    _timer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
//删除聊天数据库中的消息
- (void)delelteSessionFromDataBase:(LYTDelayDeleteInfo *)obj
{
    [[LYTSDKDataBase shareDatabase] dbChatTableDeleteMessage:obj.message.messageId targetId:obj.targetId succeed:^(BOOL result) {
        if (!result) {
            SDKLog(@"阅后即焚消息删除失败%ld",obj.message.messageId);
        }
    }];
}

//每秒刷新一次
- (void)deleteTimer:(NSTimer *)timer
{
    [self refreshDataSource];
    if (self.postDic.count) {
        [self.postDic enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString *  time, BOOL * _Nonnull stop) {
            NSArray *array = [key componentsSeparatedByString:@"##"];
            NSString *targetId = array[0];
            NSString *messageId = array[1];
            if ([self.delayDeleteDelegate respondsToSelector:@selector(deleyMessageRefreshStatuWithTargetId:messageId:showTime:)]) {
                [self.delayDeleteDelegate deleyMessageRefreshStatuWithTargetId:targetId messageId:messageId showTime:time];
            }
        }];
    }
}
@end

@implementation LYTDelayDeleteInfo
MJExtensionCodingImplementation
@end
