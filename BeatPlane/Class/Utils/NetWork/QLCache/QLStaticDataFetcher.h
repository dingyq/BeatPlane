//
//  QLStaticDataFetcher.h
//  QQLottery
//
//  Created by Jolin He on 14-3-28.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *QLHTTPErrorDomain;
extern NSString *kQLHTTPErrorURLKey;

enum ERROR_CODE {
    QLHTTPErrorNoOfflineCache = 10033,
};

@class QLStaticDataFetcher;

/**
 *  回调delegate接口
 */
@protocol QLStaticDataFetcherDelegate <NSObject>

/**
 *  成功获取数据回调
 *
 *  @param fetcher delegate消息sender对象
 *  @param data    返回的数据
 */
- (void)staticDataFetcher:(QLStaticDataFetcher*)fetcher fetchedData:(NSData*)data;

/**
 *  数据获取失败
 *
 *  @param fetcher delegate消息sender对象
 *  @param error   返回的错误对象
 */
- (void)staticDataFetcher:(QLStaticDataFetcher*)fetcher receivedError:(NSError*)error;

@optional
- (void)staticDataFetcher:(QLStaticDataFetcher*)fetcher didReceiveResponse:(NSURLResponse*)response;
/**
 *  下载进度反馈
 *
 *  @param fetcher  delegate消息sender对象
 *  @param progress 下载进度[0.0,1.0]
 */
- (void)staticDataFetcher:(QLStaticDataFetcher*)fetcher didReciveData:(NSData*)data downloadingProgressChanged:(float)progress;

/**
 *  网络状态统计信息
 *
 *  @param fetcher  delegate消息sender对象
 *  @param respSize 响应数据大小
 *  @param duration 下载耗时
 *  @param code     返回的HTTP代码
 */
- (void)staticDataFetcher:(QLStaticDataFetcher *)fetcher didLoadWithResponsePackageSize:(long long)respSize duration:(NSTimeInterval)duration returnCode:(int)code;
@end

/**
 *    QStaticDataFetcher
 *    静态数据获取类
 *    请在工程中加入QStaticCacheConfig.plist配置文件
 */
@interface QLStaticDataFetcher : NSObject

/**
 *  获取静态数据，调用后会自动获取数据。数据获取后调用delegate。
 *
 *  @param urlPath_  静态数据的url地址。如“http://imgcache.qq.com/piao/js/comm/piao_common.js”
 *  @param params_ POST请求的Body内容
 *  @param delegate_ delegate对象
 *
 *  @return 返回新建的QStaticDataFetcher对象
 */
+ (QLStaticDataFetcher*)staticDataFetcherFromURLPath:(NSString *)urlPath_ httpHeaders:(NSDictionary*)headers_ delegate:(id <QLStaticDataFetcherDelegate>)delegate_;
+ (QLStaticDataFetcher*)staticDataFetcherFromURLPath:(NSString *)urlPath_ postPatams:(NSDictionary*)params_ httpHeaders:(NSDictionary*)headers_ delegate:(id <QLStaticDataFetcherDelegate>)delegate_;
/**
 *  若有本地数据而且没有过期,立即发送staticDataFetcher:fetchedData:消息
 *
 *  @return 有本地数据且没有过期返回YES
 */
- (BOOL)sendDelegateMessageIfLocalDataAvailable;

/**
 *  取消网络请求
 */
- (void)cancel;

/**
 *  服务器数据修改时间
 */
@property(nonatomic, retain) NSDate *modifyDate;

/**
 *  自定义信息
 */
@property(nonatomic,retain) id userInfo;

/**
 *  数据的url地址
 */
@property(nonatomic, copy, readonly) NSString *urlPath;
/**
 *  数据的缓存key
 */
@property(nonatomic, readonly) NSString *cacheKey;

/**
 *  HTTP状态码，请在数据返回后调用。statusCode＝0时没有请求网络。
 */
@property(nonatomic) int statusCode;

/**
 *  标示请求是否使用的是离线数据，当为YES时可能是过期数据。
 */
@property(nonatomic, readonly) BOOL isUserOfflineData;

/**
 *  是否根据配置列表缓存动态数据，默认为全局设置（见QHTTPCacheManager），设置后会忽略全局设置。
 */
@property(nonatomic, getter = isCacheDynamicData) BOOL cacheDynamicData;

/**
 *  网络类型 wifi or cell
 */
@property(nonatomic, readonly, retain) NSString *networkType;

@end
