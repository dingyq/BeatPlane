//
//  utilityVar.h
//  QQLottery
//
//  Created by tencent_ECC on 14-4-18.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import <Foundation/Foundation.h>

//系统版本
#define SYSTEM_VERSION                              ([UIDevice currentDevice].systemVersion)
#define APP_VERSION                                 ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"])
#define APP_SHORT_VERSION                           ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"])
#define SYSTEM_VERSION_5                            ([SYSTEM_VERSION floatValue] >= 5.0 && [SYSTEM_VERSION floatValue] < 6.0)
#define SYSTEM_VERSION_5L                           ([SYSTEM_VERSION floatValue] >= 5.0)
#define SYSTEM_VERSION_6                            ([SYSTEM_VERSION floatValue] >= 6.0 && [SYSTEM_VERSION floatValue] < 7.0)
#define SYSTEM_VERSION_6L                           ([SYSTEM_VERSION floatValue] >= 6.0)
#define SYSTEM_VERSION_7L                           ([SYSTEM_VERSION floatValue] >= 7.0)

//屏幕元素尺寸
#define mScreenW                                    CGRectGetWidth([UIScreen mainScreen].bounds)
#define mScreenH                                    CGRectGetHeight([UIScreen mainScreen].bounds)
#define mIs4Inch                                    (mScreenH == 568)
#define mStatusBarH                                 20.0
#define mNavBarH                                    44.0
#define mTabBarH                                    49.0
#define mNavAndStatusBarH                           64.0
#define mOriginY                                    (SYSTEM_VERSION_7L?64.0:0.0)
//竞彩相关尺寸
#define kJcBottomViewHeight 47
#define kJcListAccessoryHeight 34

//设置颜色相关
#define mUIColorWithRGB(_r,_g,_b)                   [UIColor colorWithRed:(_r)/255.0 green:(_g)/255.0 blue:(_b)/255.0 alpha:1.0]
#define mUIColorWithRGBA(_r,_g,_b,_a)               [UIColor colorWithRed:(_r)/255.0 green:(_g)/255.0 blue:(_b)/255.0 alpha:(_a)]
#define mUIColorWithValue(rgb)                      [UIColor colorWithRed:((rgb&0xFF0000)>>16)/255.0 green:((rgb&0xFF00)>>8)/255.0 blue:(rgb&0xFF)/255.0 alpha:1]
#define mDebugShowBorder(_v,_color)                 do{\
(_v).layer.borderColor=(_color).CGColor;\
(_v).layer.borderWidth=2.0;\
} while (0)

//位操作
//设置第mask位为1
#define mBitOp_SetMask(_idx,_mask) _idx |= (1 << _mask)
//设置第mask位为0
#define mBitOp_ClearMask(_idx,_mask) _idx &= ~(1 << _mask)
//判断是否第mask位为1
#define mBitOp_HasMask(_idx,_mask) (_idx & (1 << _mask)) != 0

//全局通知的标示
#define UpdateLotteryInfo_NotificationString        @"QQLotteryMainViewUpdateInfoNotification"
#define LotteryQiHaoNameUpdate_NotificationString   @"getlotyQihaoInfoCallbackNotification"
#define ReceiveServerTime_NofitificationString      @"ReceiveServerTimeNotification"

//竞彩部分通用颜色
#define kJCColor_CellBackground [UIColor colorWithRed:246.0/255.0f green:246.0/255.0f blue:246.0/255.0f alpha:1]
#define kJCColor_RedText   [UIColor colorWithRed:219/255.0 green:21/255.0 blue:11/255.0 alpha:1.0]
#define kJCColor_LightSpLine [UIColor colorWithRed:221/255.0 green:221/255.0 blue:221/255.0 alpha:1.0]
#define kJCColor_LightGrayText [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0]
#define kJCColor_MiddleGrayText [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0]
#define kJCColor_GrayText  [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]

//颜色元素
#define redFontColor [UIColor colorWithRed:219/255.0 green:21/255.0 blue:11/255.0 alpha:1.0]
#define blueFontColor [UIColor colorWithRed:16/255.0 green:111/255.0 blue:229/255.0 alpha:1.0]
#define tipsFontColor [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0]
#define deepTipsFontColor [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]
#define lightTipsFontColor [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0]

//mybaseview 引过来
#define navigationBar_HEIGHT (SYSTEM_VERSION_7L ? 44:0)  //导航条高度
#define heightShouldBeDecreaseUsedForRefreshView (SYSTEM_VERSION_7L ? 49:120)
#define viewInitOrignYShouldBeDecrease (SYSTEM_VERSION_7L ? 0:64)

#define footerToolsBarHeight 49
#define addToListView_HEIGHT 49     //添至列表条高度
#define addToListButton_HEIGHT 34   //添至列表按钮高度
#define showChooseCountLabel_HEIGHT 30    //X注X元 标签高度
#define qihaoView_HEIGHT 30  //期号view高度
#define buyBtnView_HEIGHT 49 //购买条高度
#define buyBtn_HEIGHT 34 //按钮高度
#define kBottomViewNormalHeight 47
#define dltBottomViewHeight 81
#define kBottomViewHeight 85

#define View_HZ_HEIGHT 480
#define View_3BTH_HEIGHT 200
#define View_2THDX_HEIGHT 350
#define playStateBar_HIGHT 39
#define prizeRemindBar_HIGHT 30
/*****/

//全局变量
extern NSString* bfShowArray[31];
extern NSString* spfShowArray[3];
extern NSString* rqspfShowArray[3];
extern NSString* zjqShowArray[8];
extern NSString* bqspfShowArray[9];

extern NSString* spfLotyArray[3];
extern NSString* bfLotyArray[31];
extern NSString* zjqLotyArray[8];
extern NSString* bqspfLotyArray[9];

extern NSString* sfcShowArray[12];
extern NSString* sfcDetailsShowArray[12];
extern NSString* rfsfShowArray[2];
extern NSString* sfShowArray[2];
extern NSString* dxfShowArray[2];

extern NSString* jclqPlayIds[5];
extern NSString* jczqPlayIds[7];

extern NSString* szcArray[6]; //数字彩
extern NSString* kpcArray[6]; //快频彩
extern NSString* jjcArray[6]; //竞技彩
