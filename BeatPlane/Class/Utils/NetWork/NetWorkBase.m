//
//  NetWorkBase.m
//  QQLottery
//
//  Created by tencent_ECC on 14-3-24.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import "NetWorkBase.h"
#import "BoCaiUser.h"
#import <sys/time.h>  //for MTA
#import "NetWorkConstants.h"
#import "NSString+MD5Addition.h"
#import "UIDevice+IdentifierAddition.h"
#import "QLStaticDataFetcher.h"

#define kNetWorkRequest_TimeOutSec   60

@interface NetWorkBase ()<QLStaticDataFetcherDelegate>
{
    struct timeval m_timeval;  //记录接口请求时候时间戳用于MTA上报
}
- (NSString *)getSecKey:(NSDictionary *)paramsDic;
@property(nonatomic,retain)QLStaticDataFetcher * staticFetcher;
//for MTA
@property(nonatomic,copy)NSString * URLString;
@end

@implementation NetWorkBase
@synthesize delegate;
@synthesize didStartSelector;
@synthesize didFinishSelector;
@synthesize didFailSelector;
@synthesize staticFetcher;
//for MTA
@synthesize URLString;

- (void)dealloc
{
    self.delegate = nil;
    [staticFetcher cancel];
    self.staticFetcher=nil;
    self.URLString=nil;
    [super dealloc];
}

+(void)initialize{
    [QLHTTPCacheManager sharedInstance].defaultTimeOutInterval=kNetWorkRequest_TimeOutSec;
    [QLHTTPCacheManager sharedInstance].canUseOfflineData=YES;
    [QLHTTPCacheManager sharedInstance].cacheDynamicData=YES;
}

- (NSString *)getSecKey:(NSDictionary *)paramsDic
{
    NSMutableString * seckString = [NSMutableString stringWithString:@""];
    NSArray           * keyArray = [paramsDic allKeys];
    NSArray       * keySortArray = [keyArray sortedArrayUsingSelector:@selector(compare:)];
    for (NSString* tmpString in keySortArray) {
        [seckString appendString:tmpString];
        [seckString appendString:[paramsDic objectForKey:tmpString]];
    }
    [seckString appendString:SecretKey];
    return [[seckString stringFromMD5] lowercaseString];
}

- (void)cancelNetWork
{
    [staticFetcher cancel];
}

- (void)postDataParams:(NSDictionary *)paramDic
{
    NSString     * urlStr       = [paramDic objectForKey:NET_URL_KEY];
    NSDictionary * allParamsDic = [paramDic objectForKey:NET_PARAM_KEY];
    BoCaiUser    * user         = [BoCaiUser getUserInstance];
    
    //parameter
//    //统一增加上v_id表示当前app版本
//    NSMutableDictionary* mpdic = [NSMutableDictionary dictionaryWithDictionary:allParamsDic];
//    [mpdic setObject:APP_VERSION forKey:@"v_id"];
    
    //header
    NSMutableDictionary* headers=[NSMutableDictionary dictionary];
    [headers setObject:[self getSecKey:allParamsDic] forKey:@"seckey"];
    if(user.userSessionKey) {
        [headers setObject:user.userSessionKey forKey:@"sessionkey"];
    }
    [headers setObject:[UIDevice currentDevice].uniqueDeviceIdentifier forKey:@"uuid"];
    
    QLStaticDataFetcher* fetcher=[QLStaticDataFetcher staticDataFetcherFromURLPath:urlStr postPatams:allParamsDic httpHeaders:headers delegate:self];
    self.staticFetcher=fetcher;
    if(delegate && [delegate respondsToSelector:didStartSelector])
        [delegate performSelector:didStartSelector withObject:nil];
    
    //for MTA
    self.URLString = urlStr;
    gettimeofday(&m_timeval,NULL);
}


- (void)postDataParams:(NSDictionary *)paramDic seckeyParams:(NSDictionary *)secParams
{
    NSString     * urlStr       = [paramDic objectForKey:NET_URL_KEY];
    NSDictionary * allParamsDic = [paramDic objectForKey:NET_PARAM_KEY];
    BoCaiUser    * user         = [BoCaiUser getUserInstance];
    
    //parameter
//    //统一增加上v_id表示当前app版本
//    NSMutableDictionary* mpdic = [NSMutableDictionary dictionaryWithDictionary:allParamsDic];
//    [mpdic setObject:APP_VERSION forKey:@"v_id"];
    
    //header
    NSMutableDictionary* headers=[NSMutableDictionary dictionary];
    [headers setObject:[self getSecKey:secParams] forKey:@"seckey"];
    if(user.userSessionKey)
        [headers setObject:user.userSessionKey forKey:@"sessionkey"];
    [headers setObject:[UIDevice currentDevice].uniqueDeviceIdentifier forKey:@"uuid"];
    
    QLStaticDataFetcher* fetcher=[QLStaticDataFetcher staticDataFetcherFromURLPath:urlStr postPatams:allParamsDic httpHeaders:headers delegate:self];
    self.staticFetcher=fetcher;
    if(delegate && [delegate respondsToSelector:didStartSelector])
        [delegate performSelector:didStartSelector withObject:nil];
    
    //for MTA
    self.URLString = urlStr;
    gettimeofday(&m_timeval,NULL);
}

- (void)getDataParams:(NSString *)url
{
    BoCaiUser    * user         = [BoCaiUser getUserInstance];
    NSMutableDictionary *allParamsDic = [[[NSMutableDictionary alloc] init] autorelease];
    NSURL *u=[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSArray* arr=[u.query componentsSeparatedByString:@"&"];
    for (NSString *param in arr) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [allParamsDic setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
    }
    
    NSMutableDictionary* headers=[NSMutableDictionary dictionary];
    [headers setObject:[self getSecKey:allParamsDic] forKey:@"seckey"];
    if(user.userSessionKey)
        [headers setObject:user.userSessionKey forKey:@"sessionkey"];
    [headers setObject:[UIDevice currentDevice].uniqueDeviceIdentifier forKey:@"uuid"];
    QLStaticDataFetcher* fetcher=[QLStaticDataFetcher staticDataFetcherFromURLPath:url httpHeaders:headers delegate:self];
    self.staticFetcher=fetcher;
    if(delegate && [delegate respondsToSelector:didStartSelector])
        [delegate performSelector:didStartSelector withObject:nil];
    
    //for MTA
    self.URLString = url;
    gettimeofday(&m_timeval,NULL);
}

#pragma mark -
#pragma mark staticFetcherDelegate
- (void)staticDataFetcher:(QLStaticDataFetcher*)fetcher fetchedData:(NSData*)data{
    if(delegate && [delegate respondsToSelector:didFinishSelector])
        [delegate performSelector:didFinishSelector withObject:data];
}

- (void)staticDataFetcher:(QLStaticDataFetcher*)fetcher receivedError:(NSError*)error{
    if(delegate && [delegate respondsToSelector:didFailSelector])
        [delegate performSelector:didFailSelector withObject:error];
}

#pragma mark -
#pragma mark MTA_Interface_Report
- (void)mtaMonitorSuccess
{
    //time
    struct timeval tv;
    gettimeofday(&tv,NULL);
    long sec = tv.tv_sec  - m_timeval.tv_sec;   //s
    int  use = tv.tv_usec - m_timeval.tv_usec;  //us
    long ms  = sec * 1000 + use/1000;           //ms
    
    MTAAppMonitorStat* statObj = [[MTAAppMonitorStat alloc] init];
    statObj.interface = self.URLString;
    statObj.consumedMilliseconds = ms;
    statObj.resultType = MTA_SUCCESS;
    statObj.returnCode = 0;
    [MTA reportAppMonitorStat:statObj];
    [statObj release];
}

- (void)mtaMonitorFail
{
    //time
    struct timeval tv;
    gettimeofday(&tv,NULL);
    long sec = tv.tv_sec  - m_timeval.tv_sec;   //s
    int  use = tv.tv_usec - m_timeval.tv_usec;  //us
    long ms  = sec * 1000 + use/1000;           //ms
    
    MTAAppMonitorStat* statObj = [[MTAAppMonitorStat alloc] init];
    statObj.interface = self.URLString;
    statObj.consumedMilliseconds = ms;
    statObj.resultType = MTA_FAILURE;
    statObj.returnCode = 0;
    [MTA reportAppMonitorStat:statObj];
    [statObj release];
}

- (void)mtaMonitorLogicFail
{
    //time
    struct timeval tv;
    gettimeofday(&tv,NULL);
    long sec = tv.tv_sec  - m_timeval.tv_sec;   //s
    int  use = tv.tv_usec - m_timeval.tv_usec;  //us
    long ms  = sec * 1000 + use/1000;           //ms
    
    MTAAppMonitorStat* statObj = [[MTAAppMonitorStat alloc] init];
    statObj.interface = self.URLString;
    statObj.consumedMilliseconds = ms;
    statObj.resultType = MTA_LOGIC_FAILURE;
    statObj.returnCode = 0;
    [MTA reportAppMonitorStat:statObj];
    [statObj release];
}

@end
