//
//  BarbecueUser.h
//  BeatPlane
//
//  Created by bigqiang on 15/7/23.
//  Copyright (c) 2015年 barbecue. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kUserChangedNotify @"kUserChangedNotify"

@interface BarbecueUser : NSObject
@property (nonatomic, retain) NSString* userId;
@property (nonatomic, retain) NSString* userName;
@property (nonatomic, retain) NSString* userSessionKey;
@property (nonatomic, retain) NSString* userQQ;
@property (nonatomic, retain) NSString* userLsKey;
@property (nonatomic, assign) BOOL      isTimeOut;

+ (BarbecueUser *)getUserInstance;
+ (void)clearUserInfo;
@end
