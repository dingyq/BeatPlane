//
//  NetWork.h
//  QQLottery
//
//  Created by tencent_ECC on 14-3-21.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetWorkConstants.h"

@class NetWork;
@class NetWorkBase;

/**
 数据回调提供两种形式
 1.json解析后的字典
 2.非json格式的源数据
 所以如果你确切知道返回的数据是什么格式，只需要实现一个回调方法即可
 如果对于一个delegate同时实现了两个回调，你需要用_requestID来区分具体是哪个接口返回的数据。
 */
@protocol NetWorkDelegate <NSObject>
@optional
- (void)netWorkStartCallback:(NetWork *)netWork;
- (void)netWorkFinishedCallback:(NetWork *)netWork resultDic:(NSDictionary *)dic;
- (void)netWorkFinishedCallback:(NetWork *)netWork resultData:(NSData *)data;
- (void)netWorkFailedCallback:(NetWork *)netWork err:(NSError *)err;
@end

@interface NetWork : NSObject

@property(nonatomic,assign)id<NetWorkDelegate> delegate;
@property(nonatomic,retain)NetWorkBase * netWorkBase;
@property(assign,readonly)NetWorkRequestID requestID;
@property(nonatomic,retain)id userinfo;

/**
 cancel这个方法应该放在请求delegate的dealloc方法中调用
 防止网络延迟返回时候delegate无效造成crash
 */
+ (void)cancel:(NetWorkRequestID)requestID;

+ (NetWork *)getSfcList;
+ (NetWork *)getJcgjList;
+ (NetWork *)getAccountsDetails;
+ (NetWork *)mod:(NSDictionary*)params;

@end
