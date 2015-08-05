//
//  NetWorkBase.h
//  QQLottery
//
//  Created by tencent_ECC on 14-3-24.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASIHTTPRequest;

@interface NetWorkBase : NSObject

@property(assign)id  delegate;
@property(assign)SEL didStartSelector;
@property(assign)SEL didFinishSelector;
@property(assign)SEL didFailSelector;

- (void)cancelNetWork;
- (void)postDataParams:(NSDictionary *)paramDic;
- (void)getDataParams:(NSString *)url;
- (void)postDataParams:(NSDictionary *)paramDic seckeyParams:(NSDictionary *)secParams;
//MTA接口监控
- (void)mtaMonitorSuccess;
- (void)mtaMonitorFail;
- (void)mtaMonitorLogicFail;

@end
