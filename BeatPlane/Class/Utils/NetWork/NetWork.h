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
+ (NetWork *)getJczqList;
+ (NetWork *)getJclqList;
+ (NetWork *)getBdList;
+ (NetWork *)getStartupImage;
+ (NetWork *)getlotyQihaoInfo;
+ (NetWork *)getSoftVersion;
+ (NetWork *)GetActivityInfo;
+ (NetWork *)color;
+ (NetWork *)getuserimg;
+ (NetWork *)getLotyInfo:(NSString*)lotyName qihao:(NSString*)qihao;
+ (NetWork *)getLotyList;
+ (NetWork *)activeCenter;
+ (NetWork *)getAccountsDetails;
+ (NetWork *)mod:(NSDictionary*)params;
+ (NetWork *)getJcScore:(NSString*)keyval;
+ (NetWork *)getJcScore_jclq:(NSString*)keyval;
+ (NetWork *)getChangeScoreByBetmid:(NSString*)betID;
+ (NetWork *)getChangeScore:(NSString*)keyval;
+ (NetWork *)getAnalysisInfo_jclq:(NSString*)betID;
+ (NetWork *)getJcScene_jclq:(NSString*)betID;
+ (NetWork *)getOdds_jclq:(NSString*)betID;
+ (NetWork *)getChangeScoreByBetmid_jclq:(NSString*)betID;
+ (NetWork *)getChangeScore_jclq:(NSString*)keyval;
+ (NetWork *)addUserDeviceToken:(NSString *)deviceToken;
+ (NetWork *)modifyUserInfo:(NSString *)IDCard;
+ (NetWork *)getBetmidInofAndLogo:(NSString*)betID;
+ (NetWork *)getAnalysisInfo:(NSString*)betID;
+ (NetWork *)getEuropeOdds:(NSString*)betID;
+ (NetWork *)getAsiaOdds:(NSString*)betID;
+ (NetWork *)getJcScene:(NSString*)betID;
+ (NetWork *)feedback:(NSString *)text;
+ (NetWork *)LogOutSetPush:(NSString *)token;
+ (NetWork *)getKpLotyInfo:(NSString *)lotyName;
+ (NetWork *)getMyAccountdetail:(int)page;
+ (NetWork *)getCollectScore:(NSString*)keyval betid:(NSString*)betID;
+ (NetWork *)getHemaiList:(NSString *)type listOrder:(NSString *)sort pageSize:(int)pagesize pageNum:(int)page;
+ (NetWork *)userLogin:(NSString *)uin lskey:(NSString*)lskey deviceToken:(NSString *)token;
+ (NetWork *)userReg:(NSString *)uin name:(NSString *)userName;
+ (NetWork *)toDrawing:(NSString *)draw_money verify:(NSString *)ver realName:(NSString *)realName;
+ (NetWork *)getLotyScheme:(NSString *)proj lotyName:(NSString *)name playName:(NSString *)play fromPush:(NSString *)isFromZjPush;
+ (NetWork *)zhuihaoDetail:(NSString*)pid lotyName:(NSString*)lotyName type:(NSString*)type;
+ (NetWork *)cancelZhuihao:(NSString*)pid lotyName:(NSString*)lotyName playName:(NSString*)playName type:(NSString*)type;
+ (NetWork *)getCollectScore_jclq:(NSString*)keyval betmid:(NSString*)betID;
+ (NetWork *)getMyLotyList:(int)pageSize curPage:(int)curPage prizeNum:(int)prizeNum;
+ (NetWork *)getnorecordinfo:(int)pageSize curPage:(int)curPage;
+ (NetWork *)getawardinfo:(int)pageSize curPage:(int)curPage;
+ (NetWork *)getSpeLotyDetails:(NSString*)lotyName lotyQihao:(NSString*)lotyQihao;
+ (NetWork *)getMoreLotyKJInfo:(NSString *)lotyName page:(int)pageNum;
+ (NetWork *)appusercz:(NSString *)payTye recharge:(NSString *)recharge;
+ (NetWork *)getLotyWfInfo:(NSString *)lotyName;

+ (NetWork *)getZhuihaoList:(NSDictionary*)params style:(NetWorkRequestID)kpOrSZ;
+ (NetWork *)editUserDevice:(NSDictionary *)params deviceToken:(NSString *)token;
+ (NetWork *)addBFPushDevice:(NSDictionary*)params;
+ (NetWork *)deleteBFPushDevice:(NSDictionary*)params;
+ (NetWork *)buyWithMethod:(NSString*)method params:(NSDictionary*)params;
+ (NetWork *)joinHemaiUrl:(NSDictionary*)params;
+ (NetWork *)queryQihaoListWithLotName:(NSString *)lotName;
+ (NetWork *)buyKpIntelSerialBetsWithParams:(NSDictionary *)params lotid:(NSString *)lotid;

@end
