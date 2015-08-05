//
//  QLStaticDataFetcher.m
//  QQLottery
//
//  Created by Jolin He on 14-3-28.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//
#define ALLOW_QHTTPCacheManager_PRIVATE

#import "QLStaticDataFetcher.h"
#import "QLHTTPCacheManager.h"
#import "QLHTTPCacheManager+Private.h"
#import "QLStaticDataConfig.h"

NSString *QHTTPErrorDomain = @"QHTTPErrorDomain";
NSString *kQHTTPErrorURLKey = @"kQHTTPErrorURLKey";

extern NSString *kQLStaticDataFetcherUseOfflineDataNotification;
extern NSString *kQLStaticDataFetcherUseOnlineDataNotification;

NSString* urlEncodedStringFromDic(NSDictionary* params){
    NSMutableArray *parts = [NSMutableArray array];
    for (id key in params) {
        id value = [params objectForKey: key];
        NSString *part = [NSString stringWithFormat: @"%@=%@", [NSString stringWithFormat:@"%@",key], [NSString stringWithFormat:@"%@",value]];
        [parts addObject: part];
    }
    return [parts componentsJoinedByString: @"&"];
}

@interface QLStaticDataFetcher()
@property(nonatomic, assign) id<QLStaticDataFetcherDelegate> delegate;
@property(nonatomic, retain) NSHTTPURLResponse *response;
@property(nonatomic, retain) NSURLConnection *connection;
@property(nonatomic, retain) NSDate *expireDate;
@property(nonatomic, retain) NSInvocation *invocation;
@property(nonatomic, retain) NSString *networkType;
@property(nonatomic, retain) NSDictionary *reqParams;
@property(nonatomic, retain) NSDictionary *reqHeaders;
@end

@implementation QLStaticDataFetcher{
    NSURLConnection *connection;
    NSMutableData *receivedData;
    NSHTTPURLResponse *response;
    NSString *urlPath;
    NSDictionary* reqParams;
    NSDictionary *reqHeaders;
    NSString *cacheKey;
    NSDate *modifyDate;
    NSDate *expireDate;
    NSInvocation *invocation;
    id<QLStaticDataFetcherDelegate>delegate;
    id userInfo;
    int statusCode;
    BOOL canSendDelegateMessage;
    BOOL isUserOfflineData;
    long long dataLength;
    CFAbsoluteTime starTime;
}
@synthesize connection;
@synthesize userInfo;
@synthesize statusCode;
@synthesize delegate;
@synthesize response;
@synthesize modifyDate;
@synthesize expireDate;
@synthesize invocation;
@synthesize isUserOfflineData;
@synthesize cacheDynamicData;
@synthesize networkType;
@synthesize urlPath;
@synthesize cacheKey;
@synthesize reqParams;
@synthesize reqHeaders;

+ (NSError*)errorWithHTTPStatusCode:(int)code urlPath:(NSString*)urlPath{
    NSString *errDiscription = @"网络错误";
    switch (code) {
        case 400:
            errDiscription = @"非法请求";
            break;
        case 404:
            errDiscription = @"没有数据";
            break;
        case 408:
            errDiscription = @"请求超时";
            break;
        default:
            break;
    }
    return [NSError errorWithDomain:QHTTPErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:errDiscription,kQHTTPErrorURLKey:urlPath}];
}

- (QLStaticDataFetcher*)initWithURLPath:(NSString*)urlPath_ postPatams:(NSDictionary*)params_ httpHeaders:(NSDictionary*)headers_ delegate:(id<QLStaticDataFetcherDelegate>)delegate_{
    self = [super init];
    if (self) {
        V1Log(@"获取数据：%@",urlPath_);
        canSendDelegateMessage = YES;
        cacheDynamicData = [[QLHTTPCacheManager sharedInstance] isCacheDynamicData];
        urlPath = [urlPath_ copy];
        reqParams =[params_ retain];
        reqHeaders=[headers_ retain];
        cacheKey=[[QLHTTPCacheManager cacheKeyForURL:urlPath_ postPatams:params_] retain];
        receivedData = [[NSMutableData alloc] init];
        self.delegate = delegate_;
        if (![[QLHTTPCacheManager sharedInstance] isFileExpiredForCacheKey:cacheKey]) {
            V2Log(@"数据未过期，使用本地数据：%@",urlPath_);
            [self performSelector:@selector(sendDelegateMessageWithLocalData) withObject:nil afterDelay:0.0];
        }
        else {
            if ([QLHTTPCacheManager sharedInstance].canUseOfflineData) {
                if ([QLHTTPCacheManager sharedInstance].status==QLHTTPCacheManagerStatusUnKnown) {
                    V3Log(@"网络状态未知，等待网络监测。");
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(offlineNotify) name:kQLStaticDataFetcherUseOfflineDataNotification object:nil];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onlineNotify) name:kQLStaticDataFetcherUseOnlineDataNotification object:nil];
                }
                else if([QLHTTPCacheManager sharedInstance].status==QLHTTPCacheManagerStatusOffline){
                    isUserOfflineData = YES;
                    V2Log(@"使用离线数据：%@",urlPath_);
                    [self performSelector:@selector(sendDelegateMessageWithLocalData) withObject:nil afterDelay:0.0];
                }
                else {
                    [self connect];
                }
            }
            else{
                [self connect];
            }
        }
    }
    return self;
}

- (void)connect{
    V1Log(@"请求网络数据：%@",urlPath);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[urlPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    if (reqHeaders) {
        [request setAllHTTPHeaderFields:reqHeaders];
    }
    if (reqParams) {
        NSString* body=urlEncodedStringFromDic(reqParams);
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=utf-8"] forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d",[request.HTTPBody length]] forHTTPHeaderField:@"Content-Length"];
    }
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setHTTPShouldHandleCookies:NO];
    request.timeoutInterval = [QLHTTPCacheManager sharedInstance].defaultTimeOutInterval;
    [request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    self.modifyDate = [[QLHTTPCacheManager sharedInstance] dateForCacheKey:cacheKey];
    if (modifyDate!=nil) {
        [request setValue:[defaultDateFormatter() stringFromDate:modifyDate] forHTTPHeaderField:@"If-Modified-Since"];
    }
    V3Log(@"%@",[request allHTTPHeaderFields]);
    self.networkType = [QLHTTPCacheManager sharedInstance].networkType;
    starTime = CFAbsoluteTimeGetCurrent();
    [self.connection cancel];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)successWithData:(NSData*)data{
    [[self retain] autorelease];
    if (canSendDelegateMessage) {
        canSendDelegateMessage = NO;
        [delegate staticDataFetcher:self fetchedData:data];
    }
    else{
        QERR(@"ERROR! delegate called more than one time, url: %@\ncall stack: \n %@", urlPath,[NSThread callStackSymbols]);
    }
    self.connection = nil;
}

- (void)failWithError:(NSError*)err{
    [[self retain] autorelease];
    if (canSendDelegateMessage) {
        canSendDelegateMessage = NO;
        [delegate staticDataFetcher:self receivedError:err];
    }
    else{
        QERR(@"ERROR! delegate called more than one time, url: %@\ncall stack: \n %@", urlPath,[NSThread callStackSymbols]);
    }
    self.connection = nil;
}

- (void)setConnection:(NSURLConnection *)connection_{
    if (connection!=connection_) {
        [connection cancel];
        if (connection_!=nil) {
            [QLHTTPCacheManager sharedInstance].numberOfConnections++;
        }
        if (connection!=nil) {
            [QLHTTPCacheManager sharedInstance].numberOfConnections--;
        }
        [connection release];
        connection = [connection_ retain];
    }
}

- (void)offlineNotify{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kQLStaticDataFetcherUseOfflineDataNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kQLStaticDataFetcherUseOnlineDataNotification object:nil];
    NSData *data = [[QLHTTPCacheManager sharedInstance] localDataForCacheKey:cacheKey];
    isUserOfflineData = YES;
    if ([data length]>0) {
        [self successWithData:data];
    }
    else{
        [self failWithError:[NSError errorWithDomain:@"QLHTTPCacheManagerCache" code:QLHTTPErrorNoOfflineCache userInfo:@{NSLocalizedDescriptionKey:@"没有离线缓存数据",kQHTTPErrorURLKey:self.urlPath}]];
    }
}

- (void)onlineNotify{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kQLStaticDataFetcherUseOfflineDataNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kQLStaticDataFetcherUseOnlineDataNotification object:nil];
    if (![[QLHTTPCacheManager sharedInstance] isFileExpiredForCacheKey:cacheKey]) {
        [self performSelector:@selector(sendDelegateMessageWithLocalData) withObject:nil afterDelay:0.0];
    }
    else {
        [self connect];
    }
}

+ (QLStaticDataFetcher*)staticDataFetcherFromURLPath:(NSString *)urlPath_ httpHeaders:(NSDictionary*)headers_ delegate:(id <QLStaticDataFetcherDelegate>)delegate_{
    return [[[self alloc] initWithURLPath:urlPath_ postPatams:nil httpHeaders:headers_ delegate:delegate_] autorelease];
}

+ (QLStaticDataFetcher*)staticDataFetcherFromURLPath:(NSString *)urlPath_ postPatams:(NSDictionary*)params_ httpHeaders:(NSDictionary*)headers_ delegate:(id <QLStaticDataFetcherDelegate>)delegate_{
    return [[[self alloc] initWithURLPath:urlPath_ postPatams:params_ httpHeaders:headers_ delegate:delegate_] autorelease];
}

- (void)connection:(NSURLConnection *)connection_ didReceiveData:(NSData *)data_{
    [receivedData appendData:data_];
    if (dataLength>0&&[delegate respondsToSelector:@selector(staticDataFetcher:didReciveData:downloadingProgressChanged:)]) {
        [delegate staticDataFetcher:self didReciveData:data_ downloadingProgressChanged:((float)[receivedData length])/(float)dataLength];
    }
}

- (BOOL)sendDelegateMessageIfLocalDataAvailable{
    if(![[QLHTTPCacheManager sharedInstance] isFileExpiredForCacheKey:cacheKey]||[QLHTTPCacheManager sharedInstance].status==QLHTTPCacheManagerStatusOffline){
        if ([QLHTTPCacheManager sharedInstance].status==QLHTTPCacheManagerStatusOffline) {
            isUserOfflineData = YES;
        }
        self.connection = nil;
        NSData *data = [[QLHTTPCacheManager sharedInstance] localDataForCacheKey:cacheKey];
        if (data) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendDelegateMessageWithLocalData) object:nil];
            [self successWithData:data];
            return YES;
        }
        else{
            return NO;
        }
    }
    else {
        return NO;
    }
}

- (void)updateDateInfoWithHTTPHeader:(NSDictionary *)allHeaderFields{
    NSTimeInterval duration = -100;
    if ([allHeaderFields objectForKey:@"Last-Modified"]!=nil) {
        self.modifyDate = [defaultDateFormatter() dateFromString:[allHeaderFields objectForKey:@"Last-Modified"]];
    }
    
    if ([allHeaderFields objectForKey:@"Expires"]&&[allHeaderFields objectForKey:@"Date"]) {
        duration = [[defaultDateFormatter() dateFromString:[allHeaderFields objectForKey:@"Expires"]] timeIntervalSinceDate:[defaultDateFormatter() dateFromString:[allHeaderFields objectForKey:@"Date"]]];
    }
    
    if (duration<=0.1) {
        NSString *cacheControl = [allHeaderFields objectForKey:@"Cache-Control"];
        if ([cacheControl length]&&[cacheControl rangeOfString:@"no-cache"].location==NSNotFound) {
            NSScanner *scanner = [NSScanner scannerWithString:cacheControl];
            [scanner scanUpToString:@"max-age=" intoString:nil];
            if ([scanner scanString:@"max-age=" intoString:nil]) {
                NSTimeInterval maxAge = 0;
                [scanner scanDouble:&maxAge];
                duration = maxAge;
            }
        }
    }
    
    if (duration>0.1||([self isCacheDynamicData]&&(duration<-99||[allHeaderFields objectForKey:@"Last-Modified"]==nil))) {
        NSTimeInterval localDuration = [[QLStaticDataConfig sharedInstance] expireDurationOfCacheKey:cacheKey];
        if (localDuration>0) {
            duration = localDuration;
        }
    }
    
    if (duration<=0.1) {
        duration = 1;
    }
    
    self.expireDate = [NSDate dateWithTimeIntervalSinceNow:duration];
}


- (void)connection:(NSURLConnection *)connection_ didReceiveResponse:(NSURLResponse *)response_{
    if ([response_ isKindOfClass:[NSHTTPURLResponse class]]) {
        self.response = (NSHTTPURLResponse*)response_;
        statusCode = [response statusCode];
        NSDictionary *allHeaderFields = [response allHeaderFields];
        dataLength = [response expectedContentLength];
        V3Log(@"URL: %@",urlPath);
        V3Log(@"HTTP Code: %d",statusCode);
        V3Log(@"All Header: %@",allHeaderFields);
        
        if (statusCode==304) {
            [self updateDateInfoWithHTTPHeader:allHeaderFields];
            if(![[QLHTTPCacheManager sharedInstance] updateCacheDataForCacheKey:cacheKey modifyDate:self.modifyDate expireDate:self.expireDate]){
                QERR(@"Update file date error!");
            }
            [receivedData setData:[[QLHTTPCacheManager sharedInstance] localDataForCacheKey:cacheKey]];
        }
        if (statusCode>=400) {
            [connection cancel];
            [self failWithError:[QLStaticDataFetcher errorWithHTTPStatusCode:statusCode urlPath:self.urlPath]];
        }
    }
    if ([delegate respondsToSelector:@selector(staticDataFetcher:didReceiveResponse:)]) {
        [delegate staticDataFetcher:self didReceiveResponse:response_];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection_{
    if (statusCode==200) {
        [[QLHTTPCacheManager sharedInstance] addASuccessConnectionRecordWithTime:CFAbsoluteTimeGetCurrent()-starTime dataLength:dataLength netWorkType:self.networkType];
    }
    else {
        [[QLHTTPCacheManager sharedInstance] addASuccessConnectionRecordWithTime:0 dataLength:0 netWorkType:self.networkType];
    }
    if ([delegate respondsToSelector:@selector(staticDataFetcher:didLoadWithResponsePackageSize:duration:returnCode:)]) {
        [delegate staticDataFetcher:self didLoadWithResponsePackageSize:dataLength duration:CFAbsoluteTimeGetCurrent()-starTime returnCode:statusCode];
    }
    else{
        V3Log(@"delegate not respondsToSelector: staticDataFetcher:didLoadWithResponsePackageSize:duration:returnCode:");
    }
    
    if (statusCode<400) {
        NSData *data = [NSData dataWithData:receivedData];
        if (statusCode!=304) {
            [self updateDateInfoWithHTTPHeader:[response allHeaderFields]];
            if (![[QLHTTPCacheManager sharedInstance] storeCacheData:data forCacheKey:cacheKey modifyDate:self.modifyDate expireDate:self.expireDate]) {
                QERR(@"ERROR! 缓存存储失败，URL:%@",urlPath);
            }
        }
        [self successWithData:data];
    }
    else{
        [self failWithError:[QLStaticDataFetcher errorWithHTTPStatusCode:statusCode urlPath:self.urlPath]];
    }
}

- (void)sendDelegateMessageWithLocalData{
    NSData *data = [[QLHTTPCacheManager sharedInstance] localDataForCacheKey:cacheKey];
    if ([data length]>0) {
        [self successWithData:data];
    }
    else{
        [self failWithError:[NSError errorWithDomain:@"QLHTTPCacheManagerCache" code:QLHTTPErrorNoOfflineCache userInfo:@{NSLocalizedDescriptionKey:@"没有离线缓存数据",kQHTTPErrorURLKey:self.urlPath}]];
    }
}

- (void)cancel{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendDelegateMessageWithLocalData) object:nil];
    canSendDelegateMessage = NO;
    self.connection = nil;
    self.delegate = nil;
}

- (void)connection:(NSURLConnection *)connection_ didFailWithError:(NSError *)error{
    [self failWithError:error];
    self.connection = nil;
    [[QLHTTPCacheManager sharedInstance] addAFailureConnectionWithError:error netWorkType:self.networkType];
    if ([delegate respondsToSelector:@selector(staticDataFetcher:didLoadWithResponsePackageSize:duration:returnCode:)]) {
        [delegate staticDataFetcher:self didLoadWithResponsePackageSize:dataLength duration:CFAbsoluteTimeGetCurrent()-starTime returnCode:[error code]];
    }
    else{
        V3Log(@"delegate not respondsToSelector: staticDataFetcher:didLoadWithResponsePackageSize:duration:returnCode:");
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.connection = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendDelegateMessageWithLocalData) object:nil];
    
    [connection release];
    [urlPath release];
    [cacheKey release];
    [reqParams release];
    [reqHeaders release];
    [receivedData release];
    [userInfo release];
    [response release];
    [modifyDate release];
    [expireDate release];
    [invocation release];
    [networkType release];
    [super dealloc];
}
@end
