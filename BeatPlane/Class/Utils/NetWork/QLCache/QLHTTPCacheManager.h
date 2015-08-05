//
//  QHTTPCacheManager.h
//  QQLottery
//
//  Created by Jolin He on 14-3-28.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QLHTTPCacheManager : NSObject
/**
 *  获取全局共享对象
 *
 *  @return 全局共享QHTTPCacheManager对象
 */
+ (instancetype)sharedInstance;

/**
 *  获取请求的缓存key
 *
 *  @param urlPath 请求的url
 *
 *  @param params POST请求的Body内容，如果是GET请求传nil即可
 *
 *  @return 如果有本地缓存返回YES，不判断是否过期
 */
+(NSString*)cacheKeyForURL:(NSString*)urlPath postPatams:(NSDictionary*)params;

/**
 *  设置磁盘缓存大小
 *
 *  @param size_ 磁盘缓存大小
 */
- (void)setMaxDiskCacheSize:(NSInteger)size_;

/**
 *  清除全部缓存
 */
- (void)clearAllCache;

/**
 *  判断缓存key是否有对应的本地数据
 *
 *  @param key 要判断的缓存key
 *
 *  @return 如果有本地缓存返回YES，不判断是否过期
 */
- (BOOL)hasLocalDataForCacheKey:(NSString*)key;

/**
 *  删除某个缓存key的缓存
 *
 *  @param key 要判断的缓存key
 *
 *  @return 成功返回YES，否则返回NO
 */
- (BOOL)removeLocalDataForCacheKey:(NSString*)key;

//获取某个key的本地数据
- (NSData*)localDataForCacheKey:(NSString*)key;

//每个连接的超时时间
@property(nonatomic) NSTimeInterval defaultTimeOutInterval;

//网络统计AppId。设置后会进行网络统计。请在application:didFinishLaunchingWithOptions:里设置。
@property(nonatomic) int networkStatisticsAppId;

//所有网络连接个数
@property(nonatomic) int numberOfConnections;

//网络类型wifi or cell
@property(nonatomic, readonly, retain) NSString *networkType;

//是否可以使用离线数据，如果打开会在网络不可以的情况下提示是否使用离线数据，请在所有网络请求调用之前设置
@property(nonatomic) BOOL canUseOfflineData;

//是否根据配置缓存动态数据（全局配置），默认为NO，即动态cgi生成的数据不会被缓存起来。若设置为YES，动态数据的缓存key如果匹配配置列表也会进行缓存。
@property(nonatomic, getter = isCacheDynamicData) BOOL cacheDynamicData;

@end
