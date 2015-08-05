//
//  utilityVar.cpp
//  QQLottery
//
//  Created by 延平 黄 on 14-4-25.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#include "utilityVar.h"
#pragma mark - JCZQ
//JCZQ-show
NSString* bfShowArray[31] = {@"1:0",@"2:0",@"2:1",@"3:0",@"3:1",@"3:2",@"4:0",@"4:1",@"4:2",@"5:0",@"5:1",@"5:2",@"胜其它", @"0:0",@"1:1",@"2:2",@"3:3",@"平其它", @"0:1",@"0:2",@"1:2",@"0:3",@"1:3",@"2:3",@"0:4",@"1:4",@"2:4",@"0:5",@"1:5",@"2:5",@"负其它"};

NSString* spfShowArray[3] = {@"胜",@"平",@"负"};

NSString* rqspfShowArray[3] = {@"胜[让]",@"平[让]",@"负[让]"};

NSString* zjqShowArray[8] = {@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7+"};

NSString* bqspfShowArray[9] = {@"胜胜",@"胜平",@"胜负",@"平胜",@"平平",@"平负",@"负胜",@"负平",@"负负"};
//JCZQ-lotteryBuild
NSString* spfLotyArray[3] = {@"3", @"1", @"0"};

NSString* bfLotyArray[31] = {@"10",@"20",@"21",@"30",@"31",@"32",@"40",@"41",@"42",@"50",@"51",@"52",@"90", @"00",@"11",@"22",@"33",@"99", @"01",@"02",@"12",@"03",@"13",@"23",@"04",@"14",@"24",@"05",@"15",@"25",@"09"};

NSString* zjqLotyArray[8] = {@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7",};

NSString* bqspfLotyArray[9] = {@"33", @"31", @"30", @"13", @"11", @"10", @"03", @"01", @"00"};

NSString* jczqPlayIds[7] = {@"spf",@"rqspf",@"bf",@"zjq",@"bqspf",@"hhgg",@"hhgg2in1"};



#pragma mark - JCLQ
//JCLQ-show
NSString* sfcShowArray[12] = {@"1-5分",@"6-10分",@"11-15分",@"16-20分",@"21-25分",@"26+分",@"1-5分",@"6-10分",@"11-15分",@"16-20分",@"21-25分",@"26+分"};
NSString* sfcDetailsShowArray[12] = {@"主胜1-5",@"主胜6-10",@"主胜11-15",@"主胜16-20",@"主胜21-25",@"主胜26+",@"客胜1-5",@"客胜6-10",@"客胜11-15",@"客胜16-20",@"客胜21-25",@"客胜26+"};
NSString* rfsfShowArray[2] = {@"主负[让]",@"主胜[让]"};
NSString* sfShowArray[2] = {@"主负",@"主胜"};
NSString* dxfShowArray[2] = {@"大分",@"小分"};

NSString* jclqPlayIds[5] = {@"sf",@"rfsf",@"dxf",@"sfc",@"hhgg"};

#pragma mark - 彩种分类
NSString* szcArray[6] = {@"ssq",@"dlt",@"fc3d",@"pl3",@"pl5",@"qxc"}; //数字彩
NSString* kpcArray[6] = {@"dlc",@"syy",@"gdx",@"gkl",@"k3",@"jk"}; //快频彩
NSString* jjcArray[6] = {@"jczq",@"bq",@"jclq",@"r9",@"jcgj",@"sfc"}; //竞技彩
