//
//  NetWork.m
//  QQLottery
//
//  Created by tencent_ECC on 14-3-21.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import "NetWork.h"
#import "BoCaiUser.h"
#import "NetWorkBase.h"
#import "NSObject+SBJson.h"

/**
 管理所有类方法创建的请求的对象
 请求时候创建，请求完或者取消时候移除。
 通过NetWorkRequestID来索引唯一请求，一个请求只能有一个实例，
 如果想创建多个实例也可以方便扩展，但是对delegate的dealloc时候的关闭需要考虑
 */
static NSMutableDictionary * allNetWorkDic;

@interface NetWork (privateMethod)
- (void)netWorkStart;
- (void)netWorkFinish:(NSData *)data;
- (void)netWorkFailed:(NSError *)err;
- (void)getMethod:(NSString *)url;
- (void)postMethod:(NSDictionary *)dic;
- (void)postMethod:(NSDictionary *)dic seckeyParams:(NSDictionary *)secParams;
+ (NSString *)urlPing:(NSDictionary *)dic;
+ (NetWork *)getMethod:(NetWorkRequestID)requestid URL:(NSString *)url;
+ (NetWork *)postMethod:(NetWorkRequestID)requestid params:(NSDictionary *)param;
- (void)cancel;
@end

@implementation NetWork
@synthesize delegate;
@synthesize netWorkBase;
@synthesize requestID;

- (void)dealloc
{
    [netWorkBase cancelNetWork];
    netWorkBase.delegate=nil;
    self.netWorkBase = nil;
    self.delegate = nil;
    self.userinfo=nil;
    [super dealloc];
}

+(void)initialize
{
    allNetWorkDic = [[NSMutableDictionary dictionaryWithCapacity:60] retain];
}

#pragma mark NetWorkBase Method
- (void)netWorkStart
{
    if(delegate && [delegate respondsToSelector:@selector(netWorkStartCallback:)])
        [delegate netWorkStartCallback:self];
}

- (void)netWorkFinish:(NSData *)data
{
    if(!delegate) return;
    
    //返回的是Json字典形式数据
    if([delegate respondsToSelector:@selector(netWorkFinishedCallback:resultDic:)])
    {
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        id resultDic = [responseString JSONValue];
        
        //能够解析成字典形式
        if(resultDic && [resultDic isKindOfClass:[NSDictionary class]])
        {
            [delegate netWorkFinishedCallback:self resultDic:resultDic];
            [netWorkBase mtaMonitorSuccess];
        }
        //字典数据解析失败
        else if([delegate respondsToSelector:@selector(netWorkFailedCallback:err:)])
        {
            NSError * err = [NSError errorWithDomain:@"JsonParseErr" code:-1 userInfo:nil];
            [delegate netWorkFailedCallback:self err:err];
            [netWorkBase mtaMonitorLogicFail];
        }
        
        [responseString release];
    }
    //需要使用NSData数据形式
    if([delegate respondsToSelector:@selector(netWorkFinishedCallback:resultData:)])
    {
        //数据有效
        if(data && data.length)
        {
            [delegate netWorkFinishedCallback:self resultData:data];
            [netWorkBase mtaMonitorSuccess];
        }
        //数据无效
        else if([delegate respondsToSelector:@selector(netWorkFailedCallback:err:)])
        {
            NSError * err = [NSError errorWithDomain:@"DataParseErr" code:-1 userInfo:nil];
            [delegate netWorkFailedCallback:self err:err];
            [netWorkBase mtaMonitorLogicFail];
        }
    }
    
    //请求返回后把当前请求从allNetWorkDic保存中移除
    [NetWork cancel:requestID];
}

- (void)netWorkFailed:(NSError *)err
{
    if(delegate && [delegate respondsToSelector:@selector(netWorkFailedCallback:err:)])
        [delegate netWorkFailedCallback:self err:err];
    [netWorkBase mtaMonitorFail];
    
    //请求返回后把当前请求从allNetWorkDic保存中移除
    [NetWork cancel:requestID];
}

- (void)getMethod:(NSString *)url
{
    if(netWorkBase)
    {
        [netWorkBase cancelNetWork];
        self.netWorkBase = nil;
    }
    NetWorkBase * netWork = [[NetWorkBase alloc] init];
    netWork.delegate = self;
    netWork.didStartSelector = @selector(netWorkStart);
    netWork.didFinishSelector = @selector(netWorkFinish:);
    netWork.didFailSelector = @selector(netWorkFailed:);
    
    [netWork getDataParams:url];
    self.netWorkBase = netWork;
    [netWork release];
}

- (void)postMethod:(NSDictionary *)dic
{
    if(netWorkBase)
    {
        [netWorkBase cancelNetWork];
        self.netWorkBase = nil;
    }
    NetWorkBase * netWork = [[NetWorkBase alloc] init];
    netWork.delegate = self;
    netWork.didStartSelector = @selector(netWorkStart);
    netWork.didFinishSelector = @selector(netWorkFinish:);
    netWork.didFailSelector = @selector(netWorkFailed:);
    [netWork postDataParams:dic];
    self.netWorkBase = netWork;
    [netWork release];
}

- (void)postMethod:(NSDictionary *)dic seckeyParams:(NSDictionary *)secParams
{
    if(netWorkBase)
    {
        [netWorkBase cancelNetWork];
        self.netWorkBase = nil;
    }
    NetWorkBase * netWork = [[NetWorkBase alloc] init];
    netWork.delegate = self;
    netWork.didStartSelector = @selector(netWorkStart);
    netWork.didFinishSelector = @selector(netWorkFinish:);
    netWork.didFailSelector = @selector(netWorkFailed:);
    [netWork postDataParams:dic seckeyParams:secParams];
    self.netWorkBase = netWork;
    [netWork release];
}

//设置readonly属性
- (void)setRequestID:(NetWorkRequestID)request
{
    requestID = request;
}

//取消请求
- (void)cancel
{
    self.delegate=nil;
    [netWorkBase cancelNetWork];
    netWorkBase.delegate=nil;
    self.netWorkBase = nil;
}

/**
 将kv形式变成 “&platform=2&v_id=18&channel=ios_appstore”URL内容形式
 */
+ (NSString *)urlPing:(NSDictionary *)dic
{
    NSMutableString * resultString = [NSMutableString string];
    for(NSString * key in [dic allKeys])
    {
        [resultString appendString:key];
        [resultString appendString:@"="];
        [resultString appendString:[dic objectForKey:key]];
        [resultString appendString:@"&"];
    }
    if(resultString.length)
        return [resultString substringToIndex:resultString.length-1];
    else
        return @"";
}

+ (void)cancel:(NetWorkRequestID)requestID
{
    NSString * requestStr = [NSString stringWithFormat:@"%d",requestID];
    NetWork * netWork = [allNetWorkDic objectForKey:requestStr];
    if(netWork)
    {
        [netWork cancel];
        [allNetWorkDic removeObjectForKey:requestStr];
    }
}

+ (NetWork *)getMethod:(NetWorkRequestID)requestid URL:(NSString *)url
{
    [NetWork cancel:requestid];
    NetWork * network = [[NetWork alloc] init];
    [network getMethod:url];
    [network setRequestID:requestid];
    [allNetWorkDic setObject:network forKey:[NSString stringWithFormat:@"%d",requestid]];
    return [network autorelease];
}

+ (NetWork *)postMethod:(NetWorkRequestID)requestid params:(NSDictionary *)param
{
    [NetWork cancel:requestid];
    NetWork * network = [[NetWork alloc] init];
    [network postMethod:param];
    [network setRequestID:requestid];
    [allNetWorkDic setObject:network forKey:[NSString stringWithFormat:@"%d",requestid]];
    return [network autorelease];
}

+ (NetWork *)postMethod:(NetWorkRequestID)requestid params:(NSDictionary *)param seckeyParams:(NSDictionary *)secParams
{
    [NetWork cancel:requestid];
    NetWork * network = [[NetWork alloc] init];
    [network postMethod:param seckeyParams:secParams];
    [network setRequestID:requestid];
    [allNetWorkDic setObject:network forKey:[NSString stringWithFormat:@"%d",requestid]];
    return [network autorelease];
}

#pragma mark All Public Method
+ (NetWork *)getSfcList
{
    NSString * urlString = [NSString stringWithFormat:@"%@%@",URL_Header,URL_SFCList];
    return [NetWork getMethod:RequestID_GetSFCList URL:urlString];
}

+ (NetWork *)getJcgjList{
    NSString * urlString = [NSString stringWithFormat:@"%@%@",URL_Header,URL_JcgjList];
    return [NetWork getMethod:RequestID_GetJcgjList URL:urlString];
}

+ (NetWork *)getJczqList
{
    NSString * urlString = [NSString stringWithFormat:@"%@%@",URL_Header,URL_JczqList];
    return [NetWork getMethod:RequestID_GetJczqList URL:urlString];
}

+ (NetWork *)getJclqList
{
    NSString * urlString = [NSString stringWithFormat:@"%@%@",URL_Header,URL_JclqList];
    return [NetWork getMethod:RequestID_GetJclqList URL:urlString];
}

+ (NetWork *)getBdList
{
    NSString * urlString = [NSString stringWithFormat:@"%@%@",URL_Header,URL_BdList];
    return [NetWork getMethod:RequestID_GetBdList URL:urlString];
}

+ (NetWork *)getStartupImage
{
    // 分辨率
    CGRect                frame = [[UIScreen mainScreen] applicationFrame];
    NSString * resolutionString = [NSString stringWithFormat:@"%f-%f",CGRectGetWidth(frame), CGRectGetHeight(frame)];
    
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"getStartupImage",@"method",
                          @"2",@"platform",
                          APP_CHANNEL,@"channel",
                          SYSTEM_VERSION,@"os_version",
                          APP_VERSION,@"v_id",
                          resolutionString,@"resolution", nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetStartupImage params:allParams];
}

+ (NetWork *)addUserDeviceToken:(NSString *)deviceToken
{
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"AddUserDeviceToken",@"method",
                             deviceToken,@"devicetoken",
                             APP_SHORT_VERSION,@"version", nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_PushSeverURL,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_AddUserDeviceToken params:allParams];
}

+ (NetWork *)getHemaiList:(NSString *)type listOrder:(NSString *)sort pageSize:(int)pagesize pageNum:(int)page
{
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"getHemaiList",@"method",
                             type,@"type",
                             sort,@"sort",
                             [NSString stringWithFormat:@"%d",pagesize],@"pagesize",
                             [NSString stringWithFormat:@"%d",page],@"page",
                             nil];
    NSString * urlString  = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetHemaiList params:allParams];
}

+ (NetWork *)activeCenter
{
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"activeCenter",@"method",
                             APP_CHANNEL,@"channel",
                             APP_VERSION,@"v_id",
                             @"2",@"platform", nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_ActiveCenter params:allParams];
}

+ (NetWork *)modifyUserInfo:(NSString *)IDCard
{
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"modifyUserInfo",@"method",
                             @"identity_code",@"modify_fields",
                             IDCard,@"identity_code", nil];
    NSString * urlString  = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_ModifyUserInfo params:allParams];
}

+ (NetWork *)getAccountsDetails
{
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"getAccountsDetails",@"method",
                             [BoCaiUser getUserInstance].userId,@"uid", nil];
    NSString * urlString  = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetAccountsDetails params:allParams];
}

+ (NetWork *)userLogin:(NSString *)uin lskey:(NSString*)lskey deviceToken:(NSString *)token
{
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"userLogin",@"method",
                             uin,@"qq",
                             lskey,@"lskey",
                             token,@"token",
                             APP_SHORT_VERSION,@"version",
                             @"1",@"isiosn",nil];
    NSString * urlString  = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_UserLogin params:allParams];
}

+ (NetWork *)editUserDevice:(NSDictionary *)params deviceToken:(NSString *)token
{
    NSMutableDictionary * mutableDic = [NSMutableDictionary dictionaryWithDictionary:params];
    [mutableDic setObject:@"EditUserDevice" forKey:@"method"];
    [mutableDic setObject:token forKey:@"devicetoken"];
    [mutableDic setObject:APP_SHORT_VERSION forKey:@"version"];
        
    NSString * urlString  = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_PushSeverURL,[self urlPing:mutableDic]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,mutableDic,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_EditUserDevice params:allParams];
}

+ (NetWork *)userReg:(NSString *)uin name:(NSString *)userName
{
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"userReg",@"method",
                             uin,@"qq",
                             @"",@"idCard",
                             @"1",@"isios",
                             APP_SHORT_VERSION,@"version",
                             userName,@"username", nil];
    NSString * urlString  = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_UserReg params:allParams];
}

+ (NetWork *)getMyAccountdetail:(int)page
{
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"getMyAccountdetail",@"method",
                             @"iosaccountdetail",@"mod",
                             @"1",@"isios",
                             @"90",@"timesql",
                             [NSString stringWithFormat:@"%d",page],@"page",
                             [BoCaiUser getUserInstance].userId,@"uid", nil];
    NSString * urlString  = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetMyAccountdetail params:allParams];
}

+ (NetWork *)toDrawing:(NSString *)draw_money verify:(NSString *)ver realName:(NSString *)realName
{
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"toDrawing",@"method",
                             draw_money,@"draw_money",
                             ver,@"verify",
                             realName,@"realname",
                             [BoCaiUser getUserInstance].userId,@"uid", nil];
    NSString * urlString  = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_ToDrawing params:allParams];
}

+ (NetWork *)getLotyScheme:(NSString *)proj lotyName:(NSString *)name playName:(NSString *)play fromPush:(NSString *)isFromZjPush
{
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"getLotyScheme",@"method",
                             proj,@"project_id",
                             name,@"loty_name",
                             play,@"play_name",
                             [BoCaiUser getUserInstance].userId,@"uid",
                             APP_VERSION,@"v_id",
                             @"2",@"platform",
                             isFromZjPush,@"isPush",
                             APP_CHANNEL,@"channel", nil];
    NSString * urlString  = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetLotyScheme params:allParams];
}

+ (NetWork *)buyWithMethod:(NSString*)method params:(NSDictionary*)params
{
    NSMutableDictionary* body=[NSMutableDictionary dictionaryWithObject:method forKey:@"method"];
    [body addEntriesFromDictionary:params];
    //增加表示版本号的字段
    [body setValue:APP_VERSION forKey:@"v_id"];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];

    return [NetWork postMethod:RequestID_BuyWithMethod params:allParams];
}

+ (NetWork *)zhuihaoDetail:(NSString*)pid lotyName:(NSString*)lotyName type:(NSString*)type
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"zhuihaoDetail",@"method",
                        pid,@"zh_id",
                        lotyName,@"loty_name",
                        type,@"zh_type",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_ZhuihaoDetail params:allParams];
}

+ (NetWork *)cancelZhuihao:(NSString*)pid lotyName:(NSString*)lotyName playName:(NSString*)playName type:(NSString*)type
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"cancelZhuihao",@"method",
                        pid,@"zh_id",
                        lotyName,@"loty_name",
                        playName,@"play_name",
                        type,@"zh_type",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_CancelZhuihao params:allParams];
}

+ (NetWork *)getZhuihaoList:(NSDictionary*)params style:(NetWorkRequestID)kpOrSZ
{
    NSMutableDictionary* body=[NSMutableDictionary dictionaryWithObject:@"getZhuihaoList" forKey:@"method"];
    [body addEntriesFromDictionary:params];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:kpOrSZ params:allParams];
}

+ (NetWork *)mod:(NSDictionary*)params
{
    NSMutableDictionary* body=[NSMutableDictionary dictionaryWithObject:@"cdk" forKey:@"mod"];
    [body addEntriesFromDictionary:params];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixParty,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_Mod params:allParams];
}

+ (NetWork *)getJcScore_jclq:(NSString*)keyval
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getJcScore_jclq",@"method",
                        keyval,@"key_val",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetJcScore_jclq params:allParams];
}

+ (NetWork *)getJcScore:(NSString*)keyval
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getJcScore",@"method",
                        keyval,@"key_val",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetJcScore_jczq params:allParams];
}

+ (NetWork *)getChangeScoreByBetmid:(NSString*)betID
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getChangeScoreByBetmid",@"method",
                        betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetChangeScoreByBetmid params:allParams];
}

+ (NetWork *)getCollectScore:(NSString*)keyval betid:(NSString*)betID
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getCollectScore",@"method",
                        keyval,@"key_val",
                        betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetCollectScore params:allParams];
}

+ (NetWork *)addBFPushDevice:(NSDictionary*)params
{
    NSMutableDictionary* body=[NSMutableDictionary dictionaryWithObject:@"AddBFPushDevice" forKey:@"method"];
    [body addEntriesFromDictionary:params];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_PushSeverURL,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_AddBFPushDevice params:allParams];
}

+ (NetWork *)deleteBFPushDevice:(NSDictionary*)params
{
    NSMutableDictionary* body=[NSMutableDictionary dictionaryWithObject:@"DeleteBFPushDevice" forKey:@"method"];
    [body addEntriesFromDictionary:params];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_PushSeverURL,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_DeleteBFPushDevice params:allParams];
}

+ (NetWork *)getChangeScore:(NSString*)keyval
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getChangeScore",@"method",
                        keyval,@"key_val",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetChangeScore params:allParams];
}

+ (NetWork *)getAnalysisInfo_jclq:(NSString*)betID
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getAnalysisInfo_jclq",@"method",
                        betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetAnalysisInfo_jclq params:allParams];
}

+ (NetWork *)getJcScene_jclq:(NSString*)betID
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getJcScene_jclq",@"method",
                        betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetJcScene_jclq params:allParams];
}

+ (NetWork *)getOdds_jclq:(NSString*)betID
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getOdds_jclq",@"method",
                        betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetOdds_jclq params:allParams];
}

+ (NetWork *)getChangeScoreByBetmid_jclq:(NSString*)betID
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getChangeScoreByBetmid_jclq",@"method",
                        betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetChangeScoreByBetmid_jclq params:allParams];
}

+ (NetWork *)getChangeScore_jclq:(NSString*)keyval
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getChangeScore_jclq",@"method",
                        keyval,@"key_val",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetChangeScore_jclq params:allParams];
}

+ (NetWork *)getCollectScore_jclq:(NSString*)keyval betmid:(NSString*)betID
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getCollectScore_jclq",@"method",
                        keyval,@"key_val",
                        betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetCollectScore_jclq params:allParams];
}

+ (NetWork *)color
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:@"197,188,185",@"color",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixPhoto,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_Color params:allParams];
}

+ (NetWork *)getuserimg
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getuserimg",@"method",
                        [BoCaiUser getUserInstance].userId,@"uid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_Getuserimg params:allParams];
}

+ (NetWork *)getLotyInfo:(NSString*)lotyName qihao:(NSString*)qihao
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getLotyInfo",@"method",
                        lotyName,@"loty_name",
                        qihao,@"qihao",
                        nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetLotyInfo params:allParams];
}

+ (NetWork *)joinHemaiUrl:(NSDictionary*)params
{
    NSMutableDictionary* body=[NSMutableDictionary dictionaryWithObject:@"joinHemaiUrl" forKey:@"method"];
    [body addEntriesFromDictionary:params];
    //增加版本信息
    [body setValue:APP_VERSION forKey:@"v_id"];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_JoinHemaiUrl params:allParams];
}

+ (NetWork *)getMyLotyList:(int)pageSize curPage:(int)curPage prizeNum:(int)prizeNum
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getMyLotyList",@"method",
                        [BoCaiUser getUserInstance].userId,@"uid",
                        APP_CHANNEL,@"channel",
                        [NSString stringWithFormat:@"%d", pageSize],@"page_size",
                        [NSString stringWithFormat:@"%d", prizeNum],@"prizeNum",
                        [NSString stringWithFormat:@"%d", curPage],@"page",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetMyLotyList params:allParams];
}

+ (NetWork *)getnorecordinfo:(int)pageSize curPage:(int)curPage
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getnorecordinfo",@"method",
                        [BoCaiUser getUserInstance].userId,@"uid",
                        [NSString stringWithFormat:@"%d", pageSize],@"page_size",
                        [NSString stringWithFormat:@"%d", curPage],@"page",
                        @"1",@"isios",
                        @"iosawardrecord",@"mod",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_Getnorecordinfo params:allParams];
}

+ (NetWork *)getawardinfo:(int)pageSize curPage:(int)curPage
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getawardinfo",@"method",
                        [BoCaiUser getUserInstance].userId,@"uid",
                        [NSString stringWithFormat:@"%d", pageSize],@"page_size",
                        [NSString stringWithFormat:@"%d", curPage],@"page",
                        @"1",@"isios",
                        @"iosawardrecord",@"mod",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_Getawardinfo params:allParams];
}

+ (NetWork *)getLotyList
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:@"getLotyList",@"method",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetLotyList params:allParams];
}

+ (NetWork *)getSpeLotyDetails:(NSString*)lotyName lotyQihao:(NSString*)lotyQihao
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getSpeLotyDetails",@"method",
                        lotyName,@"loty_name",
                        lotyQihao,@"qihao",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetSpeLotyDetails params:allParams];
}

+ (NetWork *)getMoreLotyKJInfo:(NSString *)lotyName page:(int)pageNum
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getMoreLotyKJInfo",@"method",
                        lotyName,@"loty_name",
                        [NSString stringWithFormat:@"%d",pageNum],@"page",
                        @"10",@"limit",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetMoreLotyKJInfo params:allParams];
}

+ (NetWork *)getlotyQihaoInfo
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getlotyQihaoInfo",@"method",
                        PHONE_TYPE,@"platform",
                        APP_CHANNEL,@"channel",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetlotyQihaoInfo params:allParams];
}

+ (NetWork *)getSoftVersion
{
    // 分辨率
    CGRect                frame = [[UIScreen mainScreen] applicationFrame];
    NSString * resolutionString = [NSString stringWithFormat:@"%f-%f",CGRectGetWidth(frame), CGRectGetHeight(frame)];
    
    NSDictionary* body = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"getSoftVersion",@"method",
                          PHONE_TYPE,@"platform",
                          APP_CHANNEL,@"channel",
                          SYSTEM_VERSION,@"os_version",
                          APP_VERSION,@"client_version",
                          resolutionString,@"resolution", nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];

    return [NetWork postMethod:RequestID_GetSoftVersion params:allParams];
}

+ (NetWork *)GetActivityInfo
{
    NSDictionary* body = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"GetActivityInfo",@"method",
                          APP_VERSION,@"v_id",
                          APP_CHANNEL,@"channel",
                          @"2",@"platform", nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetActivityInfo params:allParams];
}

+ (NetWork *)feedback:(NSString *)text
{
    NSDictionary* body = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"feedback",@"method",
                          [BoCaiUser getUserInstance].userName,@"username",
                          PHONE_TYPE,@"phone_style",
                          SYSTEM_VERSION,@"os_version",
                          APP_SHORT_VERSION,@"client_version",
                          text,@"text", nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_Feedback params:allParams];
}

+ (NetWork *)LogOutSetPush:(NSString *)token
{
    NSMutableDictionary* body = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @"LogOutSetPush",@"method",
                                 token,@"devicetoken",
                                 nil];
    if ([BoCaiUser getUserInstance].userId != nil && ![[BoCaiUser getUserInstance].userId isEqualToString:@""]) {
        [body setObject:[BoCaiUser getUserInstance].userId forKey:@"uid"];
        if ([BoCaiUser getUserInstance].userQQ != nil && ![[BoCaiUser getUserInstance].userQQ isEqualToString:@""]) {
            [body setObject:[BoCaiUser getUserInstance].userQQ forKey:@"qqid"];
        }
    }
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_PushSeverURL,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_LogOutSetPush params:allParams];
}

+ (NetWork *)getKpLotyInfo:(NSString *)lotyName
{
    NSDictionary* body = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"getKpLotyInfo",@"method",
                          lotyName,@"loty_name",
                          @"10",@"pagesize", nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixChannel,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetKpLotyInfo params:allParams];
}

+ (NetWork *)getLotyWfInfo:(NSString *)lotyName
{
    //extra: 目前对于快频类，调用getLotyAndPlayInfo，其他的调用getlotyWFInfo
    NSString *methodStr = @"getLotyAndPlayInfo";
//    if (!lottery_is_kpc(lotyName)) {
//        methodStr = @"getlotyWFInfo";
//    } else {
//        methodStr = @"getLotyAndPlayInfo";
//    }
    
    NSDictionary* body = [NSDictionary dictionaryWithObjectsAndKeys:
                          methodStr, @"method",
                          lotyName, @"loty_name",
                          APP_VERSION, @"v_id",
                          APP_CHANNEL, @"channel",
                          SYSTEM_TYPE, @"type", nil];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@%@?%@", URL_Header, REQ_DIR, URL_SuffixChannel, [self urlPing:body]];
    NSDictionary *allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString, NET_URL_KEY, body, NET_PARAM_KEY, nil];
    return [NetWork postMethod:RequestID_GetLotyWFInfo params:allParams];
}

+ (NetWork *)appusercz:(NSString *)payTye recharge:(NSString *)recharge
{
    NSDictionary* body = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"appusercz",@"method",
                          @"addmoney",@"mod",
                          [BoCaiUser getUserInstance].userQQ,@"qq",
                          [BoCaiUser getUserInstance].userId,@"uid",
                          [BoCaiUser getUserInstance].userSessionKey,@"sessionkey",
                          APP_CHANNEL,@"channel",
                          APP_VERSION,@"v_id",
                          SYSTEM_TYPE,@"type",
                          recharge,@"deposit",
                          payTye,@"op",nil];
    //由于对于TC彩票，链接格式应该是888.qq.com/ios_sports/my/index.php?type=ios&channel=ios_sports的格式
    //但是对于QQ彩票，又应该是888.qq.com/ios/my/index.php?type=ios&channel=ios_appstore的格式，目前的宏没法支持，所以这么改
    NSString * urlString = nil;
#ifdef TCCP_PACK
    urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,APP_CHANNEL,URL_SuffixMy,[self urlPing:body]];
#endif
    if (urlString == nil) {
        urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    }
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_Appusercz params:allParams];
}

+ (NetWork *)getBetmidInofAndLogo:(NSString*)betID
{
    NSDictionary* body = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"getBetmidInofAndLogo",@"method",
                          betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetBetmidInofAndLogo params:allParams];
}

+ (NetWork *)getAnalysisInfo:(NSString*)betID
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getAnalysisInfo",@"method",
                        betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetAnalysisInfo params:allParams];
}

+ (NetWork *)getEuropeOdds:(NSString*)betID
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getEuropeOdds",@"method",
                        betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetEuropeOdds params:allParams];
}

+ (NetWork *)getAsiaOdds:(NSString*)betID
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getAsiaOdds",@"method",
                        betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetAsiaOdds params:allParams];
}

+ (NetWork *)getJcScene:(NSString*)betID
{
    NSDictionary* body=[NSDictionary dictionaryWithObjectsAndKeys:
                        @"getJcScene",@"method",
                        betID,@"betmid",nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixInfo,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetJcScene params:allParams];
}

+ (NetWork *)queryQihaoListWithLotName:(NSString *)lotName
{
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          APP_VERSION, @"v_id",
                          @"ios_qqlottery", @"channel",
                          @"queryQihaoList", @"method",
                          lotName, @"lotyname", nil];
    
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@", URL_Header, REQ_DIR, URL_SuffixChannel, [self urlPing:body]];
    
    return [NetWork getMethod:RequestID_QueryQihaoList URL:urlString];
}

+ (NetWork *)buyKpIntelSerialBetsWithParams:(NSDictionary *)params lotid:(NSString *)lotid
{
    NSString *userId = [BoCaiUser getUserInstance].userId == nil? @"": [BoCaiUser getUserInstance].userId;
    NSDictionary *urlParams = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"kpBuySelfUrl", @"method",
                               userId, @"uid",
                               lotid, @"lotid",
                               APP_VERSION,@"v_id",
                               nil];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@", URL_Header, REQ_DIR, URL_SuffixChannel, [self urlPing:urlParams]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,params,NET_PARAM_KEY, nil];
    NSMutableDictionary *secParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [secParams setObject:userId forKey:@"uid"];
    [secParams setObject:lotid forKey:@"lotid"];
    [secParams setObject:@"kpBuySelfUrl" forKey:@"method"];
    
    return [NetWork postMethod:RequestID_BuyKpIntelSerialBets params:allParams seckeyParams:secParams];
    //    return [NetWork postMethod:RequestID_BuyKpIntelSerialBets params:allParams];
}
@end

