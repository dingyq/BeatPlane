//
//  NetWork.m
//  QQLottery
//
//  Created by tencent_ECC on 14-3-21.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
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

- (void)dealloc {
    [netWorkBase cancelNetWork];
    netWorkBase.delegate=nil;
    self.netWorkBase = nil;
    self.delegate = nil;
    self.userinfo=nil;
    [super dealloc];
}

+(void)initialize {
    allNetWorkDic = [[NSMutableDictionary dictionaryWithCapacity:60] retain];
}

#pragma mark NetWorkBase Method
- (void)netWorkStart {
    if(delegate && [delegate respondsToSelector:@selector(netWorkStartCallback:)])
        [delegate netWorkStartCallback:self];
}

- (void)netWorkFinish:(NSData *)data {
    if(!delegate) return;
    
    //返回的是Json字典形式数据
    if([delegate respondsToSelector:@selector(netWorkFinishedCallback:resultDic:)]) {
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        id resultDic = [responseString JSONValue];
        
        //能够解析成字典形式
        if(resultDic && [resultDic isKindOfClass:[NSDictionary class]]) {
            [delegate netWorkFinishedCallback:self resultDic:resultDic];
            [netWorkBase mtaMonitorSuccess];
        }
        //字典数据解析失败
        else if([delegate respondsToSelector:@selector(netWorkFailedCallback:err:)]) {
            NSError * err = [NSError errorWithDomain:@"JsonParseErr" code:-1 userInfo:nil];
            [delegate netWorkFailedCallback:self err:err];
            [netWorkBase mtaMonitorLogicFail];
        }
        
        [responseString release];
    }
    //需要使用NSData数据形式
    if([delegate respondsToSelector:@selector(netWorkFinishedCallback:resultData:)]) {
        //数据有效
        if(data && data.length) {
            [delegate netWorkFinishedCallback:self resultData:data];
            [netWorkBase mtaMonitorSuccess];
        }
        //数据无效
        else if([delegate respondsToSelector:@selector(netWorkFailedCallback:err:)]) {
            NSError * err = [NSError errorWithDomain:@"DataParseErr" code:-1 userInfo:nil];
            [delegate netWorkFailedCallback:self err:err];
            [netWorkBase mtaMonitorLogicFail];
        }
    }
    
    //请求返回后把当前请求从allNetWorkDic保存中移除
    [NetWork cancel:requestID];
}

- (void)netWorkFailed:(NSError *)err {
    if(delegate && [delegate respondsToSelector:@selector(netWorkFailedCallback:err:)])
        [delegate netWorkFailedCallback:self err:err];
    [netWorkBase mtaMonitorFail];
    
    //请求返回后把当前请求从allNetWorkDic保存中移除
    [NetWork cancel:requestID];
}

- (void)getMethod:(NSString *)url {
    if(netWorkBase) {
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

- (void)postMethod:(NSDictionary *)dic {
    if(netWorkBase) {
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

- (void)postMethod:(NSDictionary *)dic seckeyParams:(NSDictionary *)secParams {
    if(netWorkBase) {
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
- (void)setRequestID:(NetWorkRequestID)request {
    requestID = request;
}

//取消请求
- (void)cancel {
    self.delegate=nil;
    [netWorkBase cancelNetWork];
    netWorkBase.delegate=nil;
    self.netWorkBase = nil;
}

/**
 将kv形式变成 “&platform=2&v_id=18&channel=ios_appstore”URL内容形式
 */
+ (NSString *)urlPing:(NSDictionary *)dic {
    NSMutableString * resultString = [NSMutableString string];
    for(NSString * key in [dic allKeys]) {
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

+ (void)cancel:(NetWorkRequestID)requestID {
    NSString * requestStr = [NSString stringWithFormat:@"%d",requestID];
    NetWork * netWork = [allNetWorkDic objectForKey:requestStr];
    if(netWork) {
        [netWork cancel];
        [allNetWorkDic removeObjectForKey:requestStr];
    }
}

+ (NetWork *)getMethod:(NetWorkRequestID)requestid URL:(NSString *)url {
    [NetWork cancel:requestid];
    NetWork * network = [[NetWork alloc] init];
    [network getMethod:url];
    [network setRequestID:requestid];
    [allNetWorkDic setObject:network forKey:[NSString stringWithFormat:@"%d",requestid]];
    return [network autorelease];
}

+ (NetWork *)postMethod:(NetWorkRequestID)requestid params:(NSDictionary *)param {
    [NetWork cancel:requestid];
    NetWork * network = [[NetWork alloc] init];
    [network postMethod:param];
    [network setRequestID:requestid];
    [allNetWorkDic setObject:network forKey:[NSString stringWithFormat:@"%d",requestid]];
    return [network autorelease];
}

+ (NetWork *)postMethod:(NetWorkRequestID)requestid params:(NSDictionary *)param seckeyParams:(NSDictionary *)secParams {
    [NetWork cancel:requestid];
    NetWork * network = [[NetWork alloc] init];
    [network postMethod:param seckeyParams:secParams];
    [network setRequestID:requestid];
    [allNetWorkDic setObject:network forKey:[NSString stringWithFormat:@"%d",requestid]];
    return [network autorelease];
}

#pragma mark All Public Method
+ (NetWork *)getSfcList {
    NSString * urlString = [NSString stringWithFormat:@"%@%@",URL_Header,URL_SFCList];
    return [NetWork getMethod:RequestID_GetSFCList URL:urlString];
}

+ (NetWork *)getJcgjList{
    NSString * urlString = [NSString stringWithFormat:@"%@%@",URL_Header,URL_JcgjList];
    return [NetWork getMethod:RequestID_GetJcgjList URL:urlString];
}

+ (NetWork *)getAccountsDetails {
    NSDictionary   * body = [NSDictionary dictionaryWithObjectsAndKeys:@"getAccountsDetails",@"method",
                             [BoCaiUser getUserInstance].userId,@"uid", nil];
    NSString * urlString  = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixMy,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_GetAccountsDetails params:allParams];
}

+ (NetWork *)mod:(NSDictionary*)params {
    NSMutableDictionary* body=[NSMutableDictionary dictionaryWithObject:@"cdk" forKey:@"mod"];
    [body addEntriesFromDictionary:params];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@%@?%@",URL_Header,REQ_DIR,URL_SuffixParty,[self urlPing:body]];
    NSDictionary * allParams = [NSDictionary dictionaryWithObjectsAndKeys:urlString,NET_URL_KEY,body,NET_PARAM_KEY, nil];
    
    return [NetWork postMethod:RequestID_Mod params:allParams];
}


@end

