//
//  LYTDelayDeleteTools
//
//  Created by Vieene on 2016/12/9.
//  Copyright © 2016年 HHLY. All rights reserved.
//

#import <Foundation/Foundation.h>
#define DelayDeleteNotification @"kDelayDeleteNotification"

@class LYTMessage;
@protocol DelayDeleteDelegate <NSObject>

/**
 阅后即焚消息即将销毁掉的监听 (DelayDeleteDelegate需要负责UI上cell的删除 ，本工具负责本地数据库的更新操作)
 @param message 阅后即焚消息对象
 */
- (void)willDeleteData:(LYTMessage *)message;

/**
 阅后即焚消息刷新时间的监听
 @param targetID 会话Id
 @param messageId 消息唯一标示
 @param time 当前需要显示的阅后即焚的时间
 */
- (void)deleyMessageRefreshStatuWithTargetId:(NSString *)targetID messageId:(NSString *)messageId showTime:(NSString *)time;

@end

@interface LYTDelayDeleteTools : NSObject
/**
 删除阅后即焚消息的代理
 */
@property (nonatomic,weak) id<DelayDeleteDelegate> delayDeleteDelegate;

+ (instancetype)sharedTools;
/**
 加入 阅后即焚的消息 到计时器
 @param message 阅后即焚消息对象
 */
- (void)addDelayMessage:(LYTMessage*)message succeed:(void (^)(BOOL))block;

/**
 根据查询当前 阅后即焚消息,最新的计时时间
 @param message 阅后即焚消息对象
 */
- (NSInteger)quaryDelayTimeForMessage:(LYTMessage *)message;
@end

@interface LYTDelayDeleteInfo : NSObject
//阅后即焚消息的延迟时间
@property (nonatomic,assign) NSInteger delayTime;
//字典的key值
@property (copy, nonatomic) NSString  *messageKey;
//阅后即焚消息对象
@property (nonatomic,strong)LYTMessage *message;
//讨论组或者单聊唯一标示
@property (nonatomic,copy) NSString *targetId;
//该消息应该删除时候的时间戳
@property (nonatomic,copy) NSString *deleteTime;
@end
