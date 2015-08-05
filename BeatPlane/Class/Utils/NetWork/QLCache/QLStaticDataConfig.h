//
//  QLStaticDataConfig.h
//  QQLottery
//
//  Created by Jolin He on 14-3-28.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QLStaticDataConfig : NSObject
+ (instancetype)sharedInstance;
- (NSTimeInterval)expireDurationOfCacheKey:(NSString*)key;
@end
