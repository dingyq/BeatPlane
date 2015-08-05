//
//  QCrypto.h
//  QQLottery
//
//  Created by Jolin He on 14-3-28.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import <Foundation/Foundation.h>

//MD5 hash
NSString *MD5(NSString *inStr);

//SHA1 hash
NSString *SHA1(NSString *inStr);


//加密数据
NSData *AESEncrytionWithDataAndKey(NSData *data, NSString *key);

//解密数据
NSData *AESDecrytionWithDataAndKey(NSData *data, NSString *key);
