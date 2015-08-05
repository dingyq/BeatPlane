//
//  User.m
//  QQLottery
//
//  Created by zhang terry on 11-9-13.
//  Copyright 2011年 海米科技. All rights reserved.
//

#import "BoCaiUser.h"

static BoCaiUser * boCaiUser = nil;

@implementation BoCaiUser

@synthesize userId;
@synthesize userName;
@synthesize userSessionKey;
@synthesize isTimeOut;
@synthesize userQQ;
@synthesize userLsKey;

+(BoCaiUser *)getUserInstance{
    @synchronized(self) {
        if (boCaiUser == nil) {
            boCaiUser=[[BoCaiUser alloc]init];
        }
    }
    return boCaiUser;
}
+(void)clearUserInfo{
    boCaiUser.userId = nil;
    boCaiUser.userName = nil;
    boCaiUser.userSessionKey = nil;
    boCaiUser.isTimeOut = TRUE;
    boCaiUser.userQQ = nil;
    boCaiUser.userLsKey = nil;
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
