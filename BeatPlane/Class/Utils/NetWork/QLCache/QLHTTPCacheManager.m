//
//  QHTTPCacheManager.m
//  QQLottery
//
//  Created by Jolin He on 14-3-28.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#define ALLOW_QHTTPCacheManager_PRIVATE
#import "QLHTTPCacheManager.h"
#import "QLHTTPCacheManager+Private.h"
#import "QlCrypto.h"
#import <sys/stat.h>
#import <dirent.h>
#import <stdlib.h>
#import <UIKit/UIKit.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <net/if.h>
#include <ifaddrs.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "QLReachability.h"
#import "QLStorageManager.h"
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

NSString *kQLStaticDataFetcherUseOfflineDataNotification = @"kQLStaticDataFetcherUseOfflineDataNotification";
NSString *kQLStaticDataFetcherUseOnlineDataNotification = @"kQLStaticDataFetcherUseOnlineDataNotification";


NSDateFormatter *defaultDateFormatter(){
    NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
    [dateFormatter setLocale:usLocale];
    [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss 'GMT'"];
    return dateFormatter;
}

int compare_stat_by_atime_desc(const void *stat1, const void *stat2){
    return ((struct stat*)stat2)->st_atime-((struct stat*)stat1)->st_atime;
}
extern NSString* urlEncodedStringFromDic(NSDictionary* params);

@interface QLHTTPCacheManager()
@property(nonatomic, retain) QLReachability *reachability;
@property(nonatomic, retain) UIAlertView *useOfflineDataAlert;
@property(nonatomic, retain) NSURLConnection *reportConnection;
@end

@implementation QLHTTPCacheManager{
    NSString *cacheRootPath;
    
    NSTimeInterval timeOffset;
    
    NSInteger maxDiskCacheSize;
    
    QLReachability *reachability;
    int numberOfConnections;
    UIAlertView *useOfflineDataAlert;
    NSMutableDictionary *cellConnectInfo;
    NSMutableDictionary *wifiConnectInfo;
    NSMutableDictionary *noNetworkConnectInfo;
}

@synthesize cacheRootPath;
@synthesize status;
@synthesize reachability;
@synthesize numberOfConnections;
@synthesize useOfflineDataAlert;
@synthesize cacheDynamicData;
@synthesize networkStatisticsAppId;
@synthesize networkType;
@synthesize canUseOfflineData;
@synthesize reportConnection;
@synthesize defaultTimeOutInterval;

+ (instancetype)sharedInstance{
    static QLHTTPCacheManager *g_QHTTPCacheManager = nil;
    @synchronized(self){
        if (g_QHTTPCacheManager==nil) {
            g_QHTTPCacheManager = [[QLHTTPCacheManager alloc] init];
        }
    }
    return g_QHTTPCacheManager;
}

+(NSString*)cacheKeyForURL:(NSString*)urlPath postPatams:(NSDictionary*)params{
    if (params) {
        return [urlPath stringByAppendingFormat:@"||%@",urlEncodedStringFromDic(params)];
    }
    return urlPath;
}

- (void)setNumberOfConnections:(int)numberOfConnections_{
    if (numberOfConnections_<0) {
        QERR(@"ERROR numberOfConnections %d",numberOfConnections_);
    }
    if (numberOfConnections_!=numberOfConnections) {
        numberOfConnections = numberOfConnections_;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = numberOfConnections>0;
    }
}


- (id)init{
    if (self = [super init]) {
        //获取缓存路径
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        if (basePath!=nil) {
            self.cacheRootPath = [basePath stringByAppendingPathComponent:@"QLStaticDataCache"];
            [[NSFileManager defaultManager] createDirectoryAtPath:self.cacheRootPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        //设置退出／进入后台时清除缓存
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearOverDiskCache) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }
        else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearOverDiskCache) name:UIApplicationWillTerminateNotification object:nil];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        defaultTimeOutInterval = 10.0f;
        
        //设置缓存大小
        if ([[NSUserDefaults standardUserDefaults] valueForKey:@"QLHTTPCacheManager.kMaxDiskCacheSize"]) {
            maxDiskCacheSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"QHTTPCacheManager.kMaxDiskCacheSize"];
        }
        else {
            maxDiskCacheSize = 15*1024*1024;
        }
        
        /*
        cellConnectInfo = [[[QLStorageManager sharedManager] restoreObjectForKey:@"QLHTTPCacheManager.cellConnectInfo"] retain];
        wifiConnectInfo = [[[QLStorageManager sharedManager] restoreObjectForKey:@"QLHTTPCacheManager.wifiConnectInfo"] retain];
        noNetworkConnectInfo = [[[QLStorageManager sharedManager] restoreObjectForKey:@"QLHTTPCacheManager.noNetworkConnectInfo"] retain];
        if(cellConnectInfo==nil)cellConnectInfo = [[NSMutableDictionary alloc] init];
        if(wifiConnectInfo==nil)wifiConnectInfo = [[NSMutableDictionary alloc] init];
        if(noNetworkConnectInfo==nil)noNetworkConnectInfo = [[NSMutableDictionary alloc] init];
        
        NSString *macAddress=[[UIDevice currentDevice].identifierForVendor UUIDString];
        [wifiConnectInfo setObject:macAddress forKey:@"deviceID"];
        [cellConnectInfo setObject:macAddress forKey:@"deviceID"];
        [noNetworkConnectInfo setObject:macAddress forKey:@"deviceID"];
        [wifiConnectInfo setObject:@"wifi" forKey:@"netType"];
        [cellConnectInfo setObject:@"cell" forKey:@"netType"];
        [noNetworkConnectInfo setObject:@"blocked" forKey:@"netType"];
        NSString *ver = APP_VERSION;
        if (ver) {
            [wifiConnectInfo setObject:ver forKey:@"appVer"];
            [cellConnectInfo setObject:ver forKey:@"appVer"];
            [noNetworkConnectInfo setObject:ver forKey:@"appVer"];
        }
        [wifiConnectInfo setObject:@0 forKey:@"failCounts"];
        [cellConnectInfo setObject:@0 forKey:@"failCounts"];
        [noNetworkConnectInfo setObject:@0 forKey:@"failCounts"];
        [wifiConnectInfo setObject:@0 forKey:@"reqSumCounts"];
        [cellConnectInfo setObject:@0 forKey:@"reqSumCounts"];
        [noNetworkConnectInfo setObject:@0 forKey:@"reqSumCounts"];
        [wifiConnectInfo setObject:@0 forKey:@"time"];
        [cellConnectInfo setObject:@0 forKey:@"time"];
        [noNetworkConnectInfo setObject:@0 forKey:@"time"];
        [wifiConnectInfo setObject:@0 forKey:@"reqSumTime"];
        [cellConnectInfo setObject:@0 forKey:@"reqSumTime"];
        [noNetworkConnectInfo setObject:@0 forKey:@"reqSumTime"];
        [wifiConnectInfo setObject:@0 forKey:@"reqSumBytes"];
        [cellConnectInfo setObject:@0 forKey:@"reqSumBytes"];
        [noNetworkConnectInfo setObject:@0 forKey:@"reqSumBytes"];
         */
        
        status = QLHTTPCacheManagerStatusOnline;
        
        self.reachability = [QLReachability reachabilityWithHostName:@"www.qq.com"];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:kReachabilityChangedNotification object:nil];
        [self.reachability startNotifier];
    }
    return self;
}

- (void)setStatus:(QLHTTPCacheManagerStatus)status_{
    if (status!=status_) {
        status = status_;
        if (status == QLHTTPCacheManagerStatusOnline) {
            V3Log(@"设置网络连通");
            [[NSNotificationCenter defaultCenter] postNotificationName:kQLStaticDataFetcherUseOnlineDataNotification object:self];
        }
        else if (status == QLHTTPCacheManagerStatusOffline){
            V3Log(@"设置离线网络");
            [[NSNotificationCenter defaultCenter] postNotificationName:kQLStaticDataFetcherUseOfflineDataNotification object:self];
        }
        else{
            V3Log(@"设置网络状态未知");
        }
    }
}

- (void)setCanUseOfflineData:(BOOL)canUseOfflineData_{
    if (canUseOfflineData!=canUseOfflineData_) {
        canUseOfflineData = canUseOfflineData_;
        if (canUseOfflineData) {
            status = QLHTTPCacheManagerStatusUnKnown;
        }
        else {
            status = QLHTTPCacheManagerStatusOnline;
        }
    }
}

- (void)reachabilityChanged{
    static int lastNetworkStatus = 100;
    NetworkStatus s = [self.reachability currentReachabilityStatus];
    if (s==NotReachable) {
        V1Log(@"网络断开");
        self.networkType = nil;
        if (lastNetworkStatus==0) {
            return;
        }
        lastNetworkStatus = 0;
        /*
        if (![self.useOfflineDataAlert isVisible]&&self.canUseOfflineData) {
            self.useOfflineDataAlert = [[[UIAlertView alloc] initWithTitle:nil message:@"目前您的网络不可用，是否要使用离线数据？" delegate:self cancelButtonTitle:@"不使用" otherButtonTitles:@"使用", nil] autorelease];
            [useOfflineDataAlert show];
        }
        */
        self.status = QLHTTPCacheManagerStatusOffline;
    }
    else{
        if (s==ReachableViaWiFi) {
            self.networkType = @"wifi";
        }
        else if(s==ReachableViaWWAN){
            self.networkType = @"cell";
        }
        V1Log(@"网络连接:%@",self.networkType);
        if (lastNetworkStatus==1) {
            return;
        }
        lastNetworkStatus = 1;
        [self.useOfflineDataAlert dismissWithClickedButtonIndex:self.useOfflineDataAlert.cancelButtonIndex animated:YES];
        self.status = QLHTTPCacheManagerStatusOnline;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex!=[alertView cancelButtonIndex]) {
        self.status = QLHTTPCacheManagerStatusOffline;
    }
    else{
        self.status = QLHTTPCacheManagerStatusOnline;
    }
    self.useOfflineDataAlert = nil;
}

- (void)setMaxDiskCacheSize:(NSInteger)size_{
    maxDiskCacheSize = size_;
    [[NSUserDefaults standardUserDefaults] setInteger:maxDiskCacheSize forKey:@"QLHTTPCacheManager.kMaxDiskCacheSize"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)clearOverDiskCache{
    if (self.networkStatisticsAppId>0) {
        [[QLStorageManager sharedManager] saveObject:wifiConnectInfo forKey:@"QLHTTPCacheManager.wifiConnectInfo"];
        [[QLStorageManager sharedManager] saveObject:cellConnectInfo forKey:@"QLHTTPCacheManager.cellConnectInfo"];
        [[QLStorageManager sharedManager] saveObject:noNetworkConnectInfo forKey:@"QLHTTPCacheManager.noNetworkConnectInfo"];
    }
    
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:self.cacheRootPath error:nil];
    NSMutableArray *fileInfos = [NSMutableArray arrayWithCapacity:[files count]];
    struct stat s;
    for (NSString *path in files) {
        path = [cacheRootPath stringByAppendingPathComponent:path];
        if (stat([path UTF8String], &s)==0) {
            [fileInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLongLong:s.st_size],@"size",path,@"path",[NSNumber numberWithLongLong:s.st_atime],@"time",nil]];
        }
        else {
            QERR(@"stat error: %@", path);
        }
        
    }
    [fileInfos sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]]];
    V1Log(@"%@",fileInfos);
    long i = 0;
    long all_size = 0;
    for (; i < [fileInfos count]; i++) {
        NSDictionary *fileInfo = [fileInfos objectAtIndex:i];
        all_size+=[[fileInfo objectForKey:@"size"] longValue];
        if (all_size>maxDiskCacheSize) {
            break;
        }
    }
    for (; i < [fileInfos count]; i++) {
        NSDictionary *fileInfo = [fileInfos objectAtIndex:i];
        remove([[fileInfo objectForKey:@"path"] UTF8String]);
    }
}

- (void)setNow:(NSDate*)date{
    timeOffset = [date timeIntervalSinceNow];
}

- (BOOL)storeCacheData:(NSData*)data forCacheKey:(NSString*)key modifyDate:(NSDate*)modifyDate expireDate:(NSDate*)expireDate{
    if (modifyDate==nil) {
        modifyDate = [NSDate date];
    }
    if (expireDate==nil) {
        expireDate = [NSDate date];
    }
    
    NSString *fileName = MD5(key);
    return [[NSFileManager defaultManager] createFileAtPath:[cacheRootPath stringByAppendingPathComponent:fileName] contents:data attributes:[NSDictionary dictionaryWithObjectsAndKeys:modifyDate,NSFileCreationDate,expireDate,NSFileModificationDate,NSFileProtectionComplete,NSFileProtectionKey,nil]];
}

- (BOOL)updateCacheDataForCacheKey:(NSString*)key modifyDate:(NSDate*)modifyDate expireDate:(NSDate*)expireDate{
    if (modifyDate==nil) {
        modifyDate = [NSDate date];
    }
    if (expireDate==nil) {
        expireDate = [NSDate date];
    }
    
    NSString *fileName = MD5(key);
    return [[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:modifyDate,NSFileCreationDate,expireDate,NSFileModificationDate,nil] ofItemAtPath:[cacheRootPath stringByAppendingPathComponent:fileName] error:nil];
}

- (void)clearAllCache{
    [[NSFileManager defaultManager] removeItemAtPath:cacheRootPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.cacheRootPath withIntermediateDirectories:YES attributes:nil error:nil];
}

- (NSDate*)dateForCacheKey:(NSString*)key{
    NSString *fileName = MD5(key);
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:[cacheRootPath stringByAppendingPathComponent:fileName] error:nil] objectForKey:NSFileCreationDate];
}

- (NSData*)localDataForCacheKey:(NSString*)key{
    NSString *fileName = MD5(key);
    NSData *data = [NSData dataWithContentsOfFile:[cacheRootPath stringByAppendingPathComponent:fileName]];
    return data;
}

- (BOOL)hasLocalDataForCacheKey:(NSString*)key{
    NSString *fileName = MD5(key);
    return [[NSFileManager defaultManager] fileExistsAtPath:[cacheRootPath stringByAppendingPathComponent:fileName]];
}

- (BOOL)removeLocalDataForCacheKey:(NSString*)key{
    NSString *fileName = MD5(key);
    return [[NSFileManager defaultManager] removeItemAtPath:[cacheRootPath stringByAppendingPathComponent:fileName] error:nil];
}

- (BOOL)isFileExpiredForCacheKey:(NSString*)key{
    NSString *fileName = MD5(key);
    NSString *cacheFilePath = [cacheRootPath stringByAppendingPathComponent:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath]) {
        return YES;
    }
    NSDate *expiredDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[cacheRootPath stringByAppendingPathComponent:fileName] error:nil] objectForKey:NSFileModificationDate];
    return expiredDate==nil||[expiredDate compare:[NSDate date]]!=NSOrderedDescending;
}

- (void)addASuccessConnectionRecordWithTime:(NSTimeInterval)t dataLength:(long long)length netWorkType:(NSString*)type{
    /*
    if(self.networkStatisticsAppId==0){
        QERR(@"网络统计App ID没有设置。");
        return;
    }
    V3Log(@"connect success time:%f length:%lld %@",t,length,type);
    if ([type isEqualToString:@"wifi"]) {
        [wifiConnectInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"time"];
        [wifiConnectInfo setObject:[NSNumber numberWithInt:1+[[wifiConnectInfo objectForKey:@"reqSumCounts"] intValue]] forKey:@"reqSumCounts"];
        [wifiConnectInfo setObject:[NSNumber numberWithDouble:[[wifiConnectInfo objectForKey:@"reqSumTime"] doubleValue]+t] forKey:@"reqSumTime"];
        [wifiConnectInfo setObject:[NSNumber numberWithLongLong:[[wifiConnectInfo objectForKey:@"reqSumBytes"] longLongValue]+length] forKey:@"reqSumBytes"];
        
    }
    else if ([type isEqualToString:@"cell"]) {
        [cellConnectInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"time"];
        [cellConnectInfo setObject:[NSNumber numberWithInt:[[cellConnectInfo objectForKey:@"reqSumCounts"] intValue]+1] forKey:@"reqSumCounts"];
        [cellConnectInfo setObject:[NSNumber numberWithDouble:[[cellConnectInfo objectForKey:@"reqSumTime"] doubleValue]+t] forKey:@"reqSumTime"];
        [cellConnectInfo setObject:[NSNumber numberWithLongLong:[[cellConnectInfo objectForKey:@"reqSumBytes"] longLongValue]+length] forKey:@"reqSumBytes"];
    }
    */
}

- (void)addAFailureConnectionWithError:(NSError*)error netWorkType:(NSString*)type{
    /*
    if(self.networkStatisticsAppId==0){
        QERR(@"网络统计App ID没有设置。");
        return;
    }
    V3Log(@"connect error:%@ %@",error,type);
    if ([type isEqualToString:@"wifi"]) {
        [wifiConnectInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"time"];
        [wifiConnectInfo setObject:[NSNumber numberWithInt:1+[[wifiConnectInfo objectForKey:@"failCounts"] intValue]] forKey:@"failCounts"];
    }
    else if ([type isEqualToString:@"cell"]) {
        [cellConnectInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"time"];
        [cellConnectInfo setObject:[NSNumber numberWithInt:1+[[cellConnectInfo objectForKey:@"failCounts"] intValue]] forKey:@"failCounts"];
    }
    else if (type==nil) {
        [noNetworkConnectInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"time"];
        [noNetworkConnectInfo setObject:[NSNumber numberWithInt:1+[[cellConnectInfo objectForKey:@"failCounts"] intValue]] forKey:@"failCounts"];
    }
     */
}

- (void)reportConnectionInfoIfNeeded{
    /*
    if(self.networkStatisticsAppId==0){
        QERR(@"网络统计App ID没有设置。");
        return;
    }
    [wifiConnectInfo setObject:[NSNumber numberWithInt:networkStatisticsAppId] forKey:@"appId"];
    [cellConnectInfo setObject:[NSNumber numberWithInt:networkStatisticsAppId] forKey:@"appId"];
    [noNetworkConnectInfo setObject:[NSNumber numberWithInt:networkStatisticsAppId] forKey:@"appId"];
    if ([[wifiConnectInfo objectForKey:@"reqSumCounts"] intValue]+[[cellConnectInfo objectForKey:@"reqSumCounts"] intValue]<50) {
        return;
    }
    V3Log(@"wifiConnectInfo: %@",wifiConnectInfo);
    V3Log(@"cellConnectInfo: %@",cellConnectInfo);
    V3Log(@"noNetworkConnectInfo: %@",noNetworkConnectInfo);
    [self.reportConnection cancel];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://test.qq.com/cgi-bin/http_quality_report.fcg"]];
    [req setHTTPMethod:@"POST"];
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:3];
    if ([[wifiConnectInfo objectForKey:@"reqSumCounts"] intValue]>0) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:wifiConnectInfo];
        [dic setObject:[NSNumber numberWithLongLong:(long long)[[dic objectForKey:@"time"] doubleValue]*1000] forKey:@"time"];
        [dic setObject:[NSNumber numberWithLongLong:(long long)[[dic objectForKey:@"reqSumTime"] doubleValue]*1000] forKey:@"reqSumTime"];
        [array addObject:dic];
    }
    if ([[cellConnectInfo objectForKey:@"reqSumCounts"] intValue]>0) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:cellConnectInfo];
        [dic setObject:[NSNumber numberWithLongLong:(long long)[[dic objectForKey:@"time"] doubleValue]*1000] forKey:@"time"];
        [dic setObject:[NSNumber numberWithLongLong:(long long)[[dic objectForKey:@"reqSumTime"] doubleValue]*1000] forKey:@"reqSumTime"];
        [array addObject:dic];
    }
    if ([[noNetworkConnectInfo objectForKey:@"failCounts"] intValue]>0) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:noNetworkConnectInfo];
        [dic setObject:[NSNumber numberWithLongLong:(long long)[[dic objectForKey:@"time"] doubleValue]*1000] forKey:@"time"];
        [dic setObject:[NSNumber numberWithLongLong:(long long)[[dic objectForKey:@"reqSumTime"] doubleValue]*1000] forKey:@"reqSumTime"];
        [array addObject:dic];
    }
    
    NSDictionary* dic=[NSDictionary dictionaryWithObject:array forKey:@"httpNetQuality"];
    NSData *jsonData=[NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString* jsonStr=nil;
    if (jsonData) {
        jsonStr=[[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];
        NSString *param = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)jsonStr, NULL, CFSTR("=:/\?&@"), kCFStringEncodingUTF8));
        [req setHTTPBody:[[NSString stringWithFormat:@"httpNetQuality=%@",param] dataUsingEncoding:NSUTF8StringEncoding]];
        self.reportConnection = [NSURLConnection connectionWithRequest:req delegate:self];
    }
     */
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection_{
    if (connection_==self.reportConnection) {
        [wifiConnectInfo removeAllObjects];
        [cellConnectInfo removeAllObjects];
    }
}

- (void)applicationBecomeActive{
    [self reportConnectionInfoIfNeeded];
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [reportConnection cancel];
    
    [reachability stopNotifier];
    [useOfflineDataAlert release];
    [cacheRootPath release];
    [reachability release];
    [reportConnection release];
    [wifiConnectInfo release];
    [cellConnectInfo release];
    [networkType release];
    [noNetworkConnectInfo release];
    [super dealloc];
}

@end