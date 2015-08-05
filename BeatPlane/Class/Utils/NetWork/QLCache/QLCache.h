//
//  QLCacheConst.h
//  QQLottery
//
//  Created by Jolin He on 14-3-28.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#ifndef _QCache_h
#define _QCache_h

#import <Foundation/Foundation.h>
#import "QLStaticDataFetcher.h"
#import "QLHTTPCacheManager.h"
#import "QLStaticDataConfig.h"
#import "QLStorageManager.h"
#import "QLCrypto.h"

#ifdef DEBUG
#define verboseQLCahce 1
#define QLOG(...)  NSLog(@"%s_%d: %@", __func__, __LINE__,[NSString stringWithFormat:__VA_ARGS__])
#else
#define verboseQLCahce 0
#define QLOG(...)
#endif
#define QERR(...)  NSLog(@"%s_%d: %@", __func__, __LINE__,[NSString stringWithFormat:__VA_ARGS__])

#define L(x) NSLocalizedString(x, x)
#define IS_IOS7_AND_LATER ([[UIDevice currentDevice].systemVersion floatValue]>6.9999)

#define V1Log(...) if(verboseQLCahce>=1) NSLog(@"%s_%d: %@", __func__, __LINE__,[NSString stringWithFormat:__VA_ARGS__])
#define V2Log(...) if(verboseQLCahce>=2) NSLog(@"%s_%d: %@", __func__, __LINE__,[NSString stringWithFormat:__VA_ARGS__])
#define V3Log(...) if(verboseQLCahce>=3) NSLog(@"%s_%d: %@", __func__, __LINE__,[NSString stringWithFormat:__VA_ARGS__])

#endif