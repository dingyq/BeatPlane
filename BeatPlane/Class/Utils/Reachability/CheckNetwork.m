//
//  CheckNetwork.m
//  QQLottery
//
//  Created by wi on 12-9-4.
//  Copyright (c) 2012年 海米科技. All rights reserved.
//

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