//
//  BarbecueUser.m
//  BeatPlane
//
//  Created by bigqiang on 15/7/23.
//  Copyright (c) 2015年 barbecue. All rights reserved.
//

#import "BarbecueUser.h"

static BarbecueUser * barbecueUser = nil;
@implementation BarbecueUser
@synthesize userId;
@synthesize userName;
@synthesize userSessionKey;
@synthesize isTimeOut;
@synthesize userQQ;
@synthesize userLsKey;

+(BarbecueUser *)getUserInstance{
    @synchronized(self) {
        if (barbecueUser == nil) {
            barbecueUser=[[BarbecueUser alloc]init];
        }
    }
    return barbecueUser;
}

+(void)clearUserInfo{
    barbecueUser.userId = nil;
    barbecueUser.userName = nil;
    barbecueUser.userSessionKey = nil;
    barbecueUser.isTimeOut = TRUE;
    barbecueUser.userQQ = nil;
    barbecueUser.userLsKey = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserChangedNotify object:nil];
}

-(void)setUserId:(NSString *)userId_{
    if (userId!=userId_) {
        [userId release];
        userId=[userId_ retain];
        [self postNotifyIfNeeded];
    }
}

-(void)setUserSessionKey:(NSString *)userSessionKey_{
    if (userSessionKey!=userSessionKey_) {
        [userSessionKey release];
        userSessionKey=[userSessionKey_ retain];
        [self postNotifyIfNeeded];
    }
}

-(void)setUserLsKey:(NSString *)userLsKey_{
    if (userLsKey!=userLsKey_) {
        [userLsKey release];
        userLsKey=[userLsKey_ retain];
        [self postNotifyIfNeeded];
    }
}

-(void)postNotifyIfNeeded{
    if (userId&&userSessionKey&&userLsKey) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserChangedNotify object:nil];
    }
}

- (void) dealloc {
    self.userId = nil;
    self.userName = nil;
    self.userSessionKey = nil;
    self.userQQ = nil;
    self.userLsKey = nil;
    
    [super dealloc];
}
    
@end
