//
//  QLStorageManager.h
//  QQLottery
//
//  Created by Jolin He on 14-3-28.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QLStorageManager : NSObject
//获取存储管理对象
+ (instancetype)sharedManager;

//保存对象，object必须支持NSCoding协议。key是保存对象的标示，若用同一个key保存2次，第一次会被覆盖
- (BOOL)saveObject:(id)object forKey:(NSString*)key;

//保存对象方法，更多参数。
//removeDate 是保存期限，超出则会被删除。
//encryption 指定保存时是否加密
- (BOOL)saveObject:(id)object forKey:(NSString*)key removeDate:(NSDate*)removeDate encryption:(BOOL)encryption;

//取回保存的对象，key是保存对象的标示。
- (id)restoreObjectForKey:(NSString*)key;

//取回保存对象，更多参数
//decryption 指定取回时是否解密
- (id)restoreObjectForKey:(NSString*)key decryption:(BOOL)decryption;
@end
