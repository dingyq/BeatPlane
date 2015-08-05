//
//  User.h
//  QQLottery
//
//  Created by zhang terry on 11-9-13.
//  Copyright 2011年 海米科技. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kUserChangedNotify @"kUserChangedNotify"

@interface BoCaiUser : NSObject

@property (nonatomic, retain) NSString* userId;
@property (nonatomic, retain) NSString* userName;
@property (nonatomic, retain) NSString* userSessionKey;
@property (nonatomic, retain) NSString* userQQ;
@property (nonatomic, retain) NSString* userLsKey;
@property (nonatomic, assign) BOOL      isTimeOut;

+ (BoCaiUser *)getUserInstance;
+ (void)clearUserInfo;
@end
