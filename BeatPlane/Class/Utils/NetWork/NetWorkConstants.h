//
//  NetWorkConstants.h
//  QQLottery
//
//  Created by tencent_ECC on 14-3-25.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

typedef enum {
    RequestID_GetSFCList,
    RequestID_GetJcgjList,
    RequestID_GetJczqList,
    RequestID_GetJclqList,
    RequestID_GetBdList,
    RequestID_GetStartupImage,
    RequestID_GetlotyQihaoInfo,
    RequestID_GetSoftVersion,
    RequestID_GetActivityInfo,
    RequestID_Color,
    RequestID_Getuserimg,
    RequestID_GetLotyInfo,
    RequestID_GetLotyList,
    RequestID_ActiveCenter,
    RequestID_GetAccountsDetails,
    RequestID_Mod,
    RequestID_GetJcScore_jclq,
    RequestID_GetJcScore_jczq,
    RequestID_GetChangeScoreByBetmid,
    RequestID_GetChangeScore,
    RequestID_GetAnalysisInfo_jclq,
    RequestID_GetJcScene_jclq,
    RequestID_GetOdds_jclq,
    RequestID_GetChangeScoreByBetmid_jclq,
    RequestID_GetChangeScore_jclq,
    RequestID_AddUserDeviceToken,
    RequestID_ModifyUserInfo,
    RequestID_GetBetmidInofAndLogo,
    RequestID_GetAnalysisInfo,
    RequestID_GetEuropeOdds,
    RequestID_GetAsiaOdds,
    RequestID_GetJcScene,
    RequestID_Feedback,
    RequestID_LogOutSetPush,
    RequestID_GetKpLotyInfo,
    RequestID_GetMyAccountdetail,
    RequestID_GetCollectScore,
    RequestID_GetHemaiList,
    RequestID_UserLogin,
    RequestID_UserReg,
    RequestID_ToDrawing,
    RequestID_GetLotyScheme,
    RequestID_ZhuihaoDetail,
    RequestID_CancelZhuihao,
    RequestID_GetCollectScore_jclq,
    RequestID_GetMyLotyList,
    RequestID_Getnorecordinfo,
    RequestID_Getawardinfo,
    RequestID_GetSpeLotyDetails,
    RequestID_GetMoreLotyKJInfo,
    RequestID_Appusercz,
    
    RequestID_GetZhuihaoList_SZC,
    RequestID_GetZhuihaoList_KPC,
    RequestID_EditUserDevice,
    RequestID_AddBFPushDevice,
    RequestID_DeleteBFPushDevice,
    RequestID_BuyWithMethod,
    RequestID_JoinHemaiUrl,
    RequestID_QueryQihaoList,
    RequestID_BuyKpIntelSerialBets,
    RequestID_GetLotyWFInfo,
    
}NetWorkRequestID;


#define PLATFORM_TYPE     @"app"
#define SYSTEM_TYPE       @"ios"
#define REQ_DIR           @"ios"
#define APP_CHANNEL       @"ios_appstore"
#define PHONE_TYPE        @"iphone"
#define WTLOGIN_APPID       568013401
#define APPSTOREID        @"550031089"

#define kWeiXinAppID                            @"wxf0eda081f23dad4f"
#define kWeiXinAppKey                           @"8fe013e7a65edd98e1d5d7e4a8624af3"
#define kTcMtaAppKey                            @"mta@hmticketa734ff"          // Mta App Key
#define kQQLotteryAppUrlSchema                 @"qqlottery"
#define kQQLotterAppUrlHeader                   @"qqlottery://qqlottery?"      // qqlottery url

#define URL_Header   @"http://888.qq.com"
#define URL_H5Base   @"http://m.888.qq.com/m"

#define URL_PushSeverURL    @"/push/iospush.php"
#define URL_SuffixMy        @"/my/index.php"
#define URL_SuffixParty     @"/party/index.php"
#define URL_SuffixInfo      @"/info/index.php"
#define URL_SuffixChannel   @"/channel/index.php"
#define URL_SuffixPhoto     @"/my/vercode.php"
#define URL_SuffixRecharge  @"/my/usercz.php?"


//针对TC彩票，定义专有的相关内容
#ifdef TCCP_PACK
#undef SYSTEM_TYPE
#undef APP_CHANNEL
#undef REQ_DIR
#undef kWeiXinAppID
#undef kWeiXinAppKey
#undef kQQLotteryAppUrlSchema
#undef kQQLotterAppUrlHeader
#undef URL_H5Base
#undef APPSTOREID

#define SYSTEM_TYPE       @"ios"
#define REQ_DIR           @"ios"
#define APP_CHANNEL       @"ios_sports"
#define kWeiXinAppID                            @"wx08a579f5ae0d04c9"
#define kWeiXinAppKey                           @"dbca1b31b9bab065f68098bd14c84bad"
#define kQQLotteryAppUrlSchema                 @"tclottery"
#define kQQLotterAppUrlHeader                   @"tclottery://tclottery?"      // qqlottery url
#define URL_H5Base   @"http://m.888.qq.com/m_sports"
#define APPSTOREID        @"743525884"
#endif

//针对iTools
#ifdef ITOOLS_PACK
#undef APP_CHANNEL
#undef REQ_DIR

#define REQ_DIR           @"ios_itools"
#define APP_CHANNEL       @"ios_itools"
#endif

//针对91
#ifdef WL91_PACK
#undef APP_CHANNEL
#undef REQ_DIR

#define REQ_DIR           @"ios_91"
#define APP_CHANNEL       @"ios_91"
#endif

//针对同步推
#ifdef TONGBU_PACK
#undef APP_CHANNEL
#undef REQ_DIR

#define REQ_DIR           @"ios_tongbu"
#define APP_CHANNEL       @"ios_tongbu"
#endif


#define URL_SFCList  @"/static/mobile_app/ios/public/football/sfc_match.js"
#define URL_JcgjList @"/static/mobile_app/ios/public/football/jcgj_list_app_data.js"
#define URL_JczqList @"/static/mobile_app/ios/public/jc/jczq_hhgg_match.js"
#define URL_JclqList @"/static/mobile_app/ios/public/jc/jclq_hhgg_match.js"
#define URL_BdList   @"/static/mobile_app/ios/public/bd/match.js"

#pragma mark - 外调说明，帮助页面
//双色球：
#define URL_WFSM_SSQ @"http://kf.qq.com/touch/apifaq/120227eA77J3140529QVNrQF.html?platform=15"
//大乐透：
#define URL_WFSM_DLT @"http://kf.qq.com/touch/apifaq/120227eA77J3140529ZbuAfE.html?platform=15"
//竞彩足球：
#define URL_WFSM_JCZQ @"http://kf.qq.com/touch/apifaq/120227eA77J3140528aYzYNN.html?platform=15"
//竞彩篮球：
#define URL_WFSM_JCLQ @"http://kf.qq.com/touch/apifaq/120227eA77J3140529fQFR3q.html?platform=15"
//广东11选5：
#define URL_WFSM_GDX @"http://kf.qq.com/touch/apifaq/120227eA77J3140528Mva2qu.html?platform=15"

//江西11选5：
#define URL_WFSM_DLC @"http://kf.qq.com/touch/apifaq/120227eA77J3140529eQ77fA.html?platform=15"

//十一运夺金：
#define URL_WFSM_SYY @"http://kf.qq.com/touch/apifaq/120227eA77J3140529i2UvAz.html?platform=15"

//江苏快3：
#define URL_WFSM_K3 @"http://kf.qq.com/touch/apifaq/120227eA77J3140528BJJzae.html?platform=15"

//吉林快3：
#define URL_WFSM_JK @"http://kf.qq.com/touch/apifaq/120227eA77J3140529yymArA.html?platform=15"

//快乐10分：
#define URL_WFSM_GKL @"http://kf.qq.com/touch/apifaq/120227eA77J3140529NrmuIj.html?platform=15"

//福彩3D：
#define URL_WFSM_FC3D @"http://kf.qq.com/touch/apifaq/120227eA77J31405296vAnym.html?platform=15"

//七星彩：
#define URL_WFSM_QXC @"http://kf.qq.com/touch/apifaq/120227eA77J31405293i6nyY.html?platform=15"

//排列三：
#define URL_WFSM_PL3 @"http://kf.qq.com/touch/apifaq/120227eA77J3140529ARniYV.html?platform=15"

//排列五：
#define URL_WFSM_PL5 @"http://kf.qq.com/touch/apifaq/120227eA77J3140529imquqQ.html?platform=15"

//足球单场：
#define URL_WFSM_BD @"http://kf.qq.com/touch/apifaq/120227eA77J3140529YFN7RZ.html?platform=15"

//胜负彩：
#define URL_WFSM_SFC @"http://kf.qq.com/touch/apifaq/120227eA77J3140529VvYJrU.html?platform=15"

//任选九场：
#define URL_WFSM_R9 @"http://kf.qq.com/touch/apifaq/120227eA77J3140529QRB3Qb.html?platform=15"

//竞猜冠军：
#define URL_WFSM_JCGJ @"http://kf.qq.com/touch/apifaq/120227eA77J3140529ZZZBji.html?platform=15"

//
#define URL_WFSM_HemaiHall @"http://kf.qq.com/touch/faqlist/faqlist_app.html?s=3853&m=3899&platform=15&title=%E5%90%88%E4%B9%B0%E3%80%81%E8%BF%BD%E5%8F%B7%E7%9B%B8%E5%85%B3%E8%A7%84%E5%88%99&platform=15&ADTAG=veda.caipiao.app&tj_src=app"

//
#define URL_WFSM_HelpCenter @"http://kf.qq.com/touch/product/caipiao_platform_app.html?ADTAG=veda.caipiao.app&tj_src=app"



#define URL_PlayIntroduction   [URL_H5Base stringByAppendingString:@"/award/app/details/"]
#define URL_AppRecommend       [URL_H5Base stringByAppendingString:@"/user/apprecommend.shtml"]
#define URL_UserPact           [URL_H5Base stringByAppendingString:@"/user/userpact.shtml"]
#define URL_HeMaiDaTing        [URL_H5Base stringByAppendingString:@"/#type=url&url=buy/detail_hm.shtml?"]
#define URL_LotteryListURL     [URL_H5Base stringByAppendingString:@"/#type=url&url=buy/%@.shtml?"]
#define URL_JcLotteryListURL   [URL_H5Base stringByAppendingString:@"/#type=url&url=buy/%@.shtml?"]

#define SecretKey    @"5xa30nt4qccnbaff4lvcpsvqyn1fh5gc"
#define CommonKey    @"0123456789qwertyuipasdfghjklzxcvbnm"

#define NET_URL_KEY    @"requestURL"
#define NET_PARAM_KEY  @"paramDic"
