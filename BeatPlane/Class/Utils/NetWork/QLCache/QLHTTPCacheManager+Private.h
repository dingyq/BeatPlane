/*
 *  QHTTPCacheManager+Private.h
 *  QQTicket2
 *
 *  Created by Jolin He on 11-12-9.
 *  Copyright 2011 iPhone Dev. All rights reserved.
 *
 */

#import "QLHTTPCacheManager.h"
#ifndef ALLOW_QHTTPCacheManager_PRIVATE
#error 私有头文件请不要使用
#endif
NSDateFormatter *defaultDateFormatter();

typedef enum QLHTTPCacheManagerStatus{
    QLHTTPCacheManagerStatusUnKnown,
    QLHTTPCacheManagerStatusOnline,
    QLHTTPCacheManagerStatusOffline
}QLHTTPCacheManagerStatus;



@interface QLHTTPCacheManager()

@property(nonatomic,retain) NSString *cacheRootPath;

@property(nonatomic) QLHTTPCacheManagerStatus status;

@property(nonatomic, retain) NSString *networkType;

- (NSDate*)dateForCacheKey:(NSString*)key;

- (BOOL)storeCacheData:(NSData*)data forCacheKey:(NSString*)key modifyDate:(NSDate*)modifyDate expireDate:(NSDate*)expireDate;

- (BOOL)updateCacheDataForCacheKey:(NSString*)key modifyDate:(NSDate*)modifyDate expireDate:(NSDate*)expireDate;

- (BOOL)isFileExpiredForCacheKey:(NSString*)key;

- (void)setNow:(NSDate*)date;

- (void)addASuccessConnectionRecordWithTime:(NSTimeInterval)t dataLength:(long long)length netWorkType:(NSString*)type;
- (void)addAFailureConnectionWithError:(NSError*)error netWorkType:(NSString*)type;

@end
