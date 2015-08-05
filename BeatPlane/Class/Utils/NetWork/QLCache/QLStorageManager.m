//
//  QLStorageManager.m
//  QQLottery
//
//  Created by Jolin He on 14-3-28.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import "QLStorageManager.h"
#import "QLCrypto.h"
#include <sys/xattr.h>

#define DES_KEY_SUFFIX @"%$()bRxQ78^7fdJD32*9"

@interface QLStorageManager()
@property(nonatomic, retain) NSString *cacheRootPath;
@end

@implementation QLStorageManager
@synthesize cacheRootPath;

+ (instancetype)sharedManager{
    static QLStorageManager *g_QCacheManager = nil;
    @synchronized(self){
        if (g_QCacheManager==nil) {
            g_QCacheManager = [[QLStorageManager alloc] init];
        }
    }
    return g_QCacheManager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        if (basePath!=nil) {
            self.cacheRootPath = [[basePath stringByAppendingPathComponent:@"Private Documents"] stringByAppendingPathComponent:@"QLDataStorage"];
            [[NSFileManager defaultManager] createDirectoryAtPath:self.cacheRootPath withIntermediateDirectories:YES attributes:nil error:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearExpireCache) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }
    }
    return self;
}

- (void)clearExpireCache{
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:self.cacheRootPath error:nil];
    NSDate *now = [NSDate date];
    for (NSString *path in files) {
        path = [cacheRootPath stringByAppendingPathComponent:path];
        const char* cfilePath = [path fileSystemRepresentation];
        const char* attrExpireDate = "com.qq.QLStorageManager.expireDate";
        double expireTimestamp = 0;
        getxattr(cfilePath, attrExpireDate, &expireTimestamp, sizeof(expireTimestamp), 0, 0);
        NSDate *expireDate = [NSDate dateWithTimeIntervalSince1970:expireTimestamp];
        if (expireDate) {
            if ([expireDate compare:now]==NSOrderedAscending) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
            }
        }
    }
}

- (BOOL)saveObject:(id)object forKey:(NSString*)key removeDate:(NSDate*)date encryption:(BOOL)encryption{
    if ([key length]==0) {
        return NO;
    }
    NSString *fileName = MD5(key);
    NSString *filePath = [self.cacheRootPath stringByAppendingPathComponent:fileName];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    if (encryption) {
        data = AESEncrytionWithDataAndKey(data, [fileName stringByAppendingString:DES_KEY_SUFFIX]);
    }
    if (data!=nil&&[[NSFileManager defaultManager] createFileAtPath:filePath contents:data attributes:nil]) {
        //set do not backup
        const char* cfilePath = [filePath fileSystemRepresentation];
        const char* attrBackup = "com.apple.MobileBackup";
        u_int8_t attrValue = 1;
        setxattr(cfilePath, attrBackup, &attrValue, sizeof(attrValue), 0, 0);
        
        //set expiredate
        const char* attrExpireDate = "com.qq.QLStorageManager.expireDate";
        double attrDate = [date timeIntervalSince1970];
        setxattr(cfilePath, attrExpireDate, &attrDate, sizeof(attrDate), 0, 0);
        return YES;
    }
    else{
        QERR(@"ERROR: writeCacheData %@",key);
        return NO;
    }
}

- (BOOL)saveObject:(id)object forKey:(NSString*)key{
    return [self saveObject:object forKey:key removeDate:[NSDate dateWithTimeIntervalSinceNow:3*31*24*3600] encryption:NO];
}

- (id)restoreObjectForKey:(NSString*)key{
    return [self restoreObjectForKey:key decryption:NO];
}

- (id)restoreObjectForKey:(NSString*)key decryption:(BOOL)decryption{
    if ([key length]==0) {
        QERR(@"ERROR: key is empty!");
        return nil;
    }
    NSString *fileName = MD5(key);
    NSData *data = [NSData dataWithContentsOfFile:[self.cacheRootPath stringByAppendingPathComponent:fileName]];
    if ([data length]==0) {
        V1Log(@"ERROR: No file data for key %@",key);
        return nil;
    }
    if (decryption) {
        data = AESDecrytionWithDataAndKey(data, [fileName stringByAppendingString:DES_KEY_SUFFIX]);
    }
    id ret = nil;
    @try {
        ret = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch (NSException *exception) {
        QERR(@"ERROR %@",exception);
    }
    @finally {
        
    }
    return ret;
}
@end
