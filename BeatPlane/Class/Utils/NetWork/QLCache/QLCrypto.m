//
//  QCrypto.m
//  QQLottery
//
//  Created by Jolin He on 14-3-28.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import "QLCrypto.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

NSString* MD5(NSString* inStr){
	unsigned char md5[CC_MD5_DIGEST_LENGTH] = {0};
	CC_MD5([inStr UTF8String], [inStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding], md5);
	NSMutableString *md5str = [NSMutableString string];
	for (int i=0; i<CC_MD5_DIGEST_LENGTH; i++) {
		[md5str appendFormat:@"%02X",md5[i]];
	}
	return [NSString stringWithString:md5str];
}

NSString *SHA1(NSString *inStr){
    unsigned char sha1[CC_SHA1_DIGEST_LENGTH] = {0};
    CC_SHA1([inStr UTF8String], [inStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding], sha1);
    NSMutableString *sha1Str = [NSMutableString string];
	for (int i=0; i<CC_SHA1_DIGEST_LENGTH; i++) {
		[sha1Str appendFormat:@"%02X",sha1[i]];
	}
	return [NSString stringWithString:sha1Str];
}

NSData *AESEncrytionWithDataAndKey(NSData *data, NSString *key){
    if ([data length]==0||[key length]==0) {
        return nil;
    }
	unsigned char md5[16] = {0};
	CC_MD5([key UTF8String], [key lengthOfBytesUsingEncoding:NSUTF8StringEncoding], md5);
    unsigned char *encrytionData = malloc([data length]);
    size_t requiredSize = 0;
    CCCryptorStatus status;
    status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, md5, kCCKeySizeAES128, NULL, [data bytes], [data length], encrytionData, [data length], &requiredSize);
    if (status==kCCBufferTooSmall) {
        encrytionData = realloc(encrytionData, requiredSize);
        status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, md5, kCCKeySizeAES128, NULL, [data bytes], [data length], encrytionData, requiredSize, &requiredSize);
    }
    if (status==kCCSuccess) {
        return [NSData dataWithBytesNoCopy:encrytionData length:requiredSize];
    }
    else {
        free(encrytionData);
        QERR(@"ERROR: CCCryptorStatus:%d", status);
        return nil;
    }
}

NSData *AESDecrytionWithDataAndKey(NSData *data, NSString *key){
    if ([data length]==0||[key length]==0) {
        QERR(@"ERROR: data or key empty!");
        return nil;
    }
    unsigned char *decrytionData = malloc([data length]);
    size_t requiredSize = 0;
    CCCryptorStatus status;
    unsigned char md5[16] = {0};
	CC_MD5([key UTF8String], [key lengthOfBytesUsingEncoding:NSUTF8StringEncoding], md5);
    status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, md5, kCCKeySizeAES128, NULL, [data bytes], [data length], decrytionData, [data length], &requiredSize);
    if (status==kCCBufferTooSmall) {
        decrytionData = realloc(decrytionData, requiredSize);
        status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, md5, kCCKeySizeAES128, NULL, [data bytes], [data length], decrytionData, requiredSize, &requiredSize);
    }
    if (status==kCCSuccess) {
        return [NSData dataWithBytesNoCopy:decrytionData length:requiredSize];
    }
    else {
        free(decrytionData);
        QERR(@"ERROR: CCCryptorStatus:%d", status);
        return nil;
    }
}