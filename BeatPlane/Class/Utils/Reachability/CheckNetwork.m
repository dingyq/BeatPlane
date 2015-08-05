//
//  CheckNetwork.m
//  BeatPlane
//
//  Created by bigqiang on 15/7/23.
//  Copyright (c) 2015年 barbecue. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CheckNetwork.h"
#import "Reachability.h"
@implementation CheckNetwork
+(BOOL)isExistenceNetwork
{
	BOOL isExistenceNetwork;
	Reachability *r = [Reachability reachabilityWithHostName:@"www.apple.com"];
    switch ([r currentReachabilityStatus]) 
    {
        case NotReachable:
			isExistenceNetwork=FALSE;
            break;
        case ReachableViaWWAN:
			isExistenceNetwork=TRUE;
            break;
        case ReachableViaWiFi:
			isExistenceNetwork=TRUE;
            break;
    }
	if (!isExistenceNetwork) 
    {
		UIAlertView *myalert = [[UIAlertView alloc] initWithTitle:nil message:@"网络连接不可用，请检查网络设置" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
		[myalert show];
		[myalert release];
	}
	return isExistenceNetwork;
}
@end