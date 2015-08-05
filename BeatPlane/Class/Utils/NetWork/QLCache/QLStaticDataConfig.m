//
//  QLStaticDataConfig.m
//  QQLottery
//
//  Created by Jolin He on 14-3-28.
//  Copyright (c) 2014年 海米科技. All rights reserved.
//

#import "QLStaticDataConfig.h"

@interface QLStaticDataConfig ()

@property(nonatomic,retain) NSMutableDictionary *dicCacheConfig;
@property(nonatomic,retain) NSMutableArray      *arrConfig;

@end

@implementation QLStaticDataConfig{
    NSMutableDictionary *dicCacheConfig;
    NSMutableArray      *arrConfig;
}
@synthesize dicCacheConfig;
@synthesize arrConfig;

+ (instancetype)sharedInstance{
    static QLStaticDataConfig *g_QHTTPCacheConfig = nil;
    @synchronized(self){
        if (g_QHTTPCacheConfig==nil) {
            g_QHTTPCacheConfig = [[QLStaticDataConfig alloc] init];
        }
    }
    return g_QHTTPCacheConfig;
}

- (id)init{
    self = [super init];
    if (self) {
        NSString *errorDesc = nil;
        NSPropertyListFormat format =NSPropertyListXMLFormat_v1_0;
        NSString *plistPath;
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                  NSUserDomainMask, YES) objectAtIndex:0];
        plistPath = [rootPath stringByAppendingPathComponent:@"QLStaticCacheConfig.plist"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            plistPath = [[NSBundle mainBundle] pathForResource:@"QLStaticCacheConfig" ofType:@"plist"];
        }
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        self.dicCacheConfig = (NSMutableDictionary *)[NSPropertyListSerialization
                                                      propertyListFromData:plistXML
                                                      mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                      format:&format
                                                      errorDescription:&errorDesc];
        
        if (!dicCacheConfig) {
            [errorDesc release];
        }
        self.arrConfig = [NSMutableArray arrayWithArray:[dicCacheConfig objectForKey:@"patterns"]];
    }
    return self;
}

- (NSTimeInterval)expireDurationOfCacheKey:(NSString*)key
{
    if (!arrConfig)
    {
        NSLog(@"Error ! arrConfig is nil");
        return 0;
    }
    __block NSTimeInterval interval=0;
    [arrConfig enumerateObjectsUsingBlock:^(id dicItem, NSUInteger idx, BOOL *stop) {
        NSString* pattern = [dicItem objectForKey:@"pattern"];
        
        NSError *error = NULL;
        NSRegularExpression* regExp = [NSRegularExpression regularExpressionWithPattern:(NSString*)pattern options:NSRegularExpressionCaseInsensitive error:&error];
        NSRange range = NSMakeRange(0,[key length]);
        NSUInteger count = [regExp numberOfMatchesInString:key options:NSRegularExpressionIgnoreMetacharacters range:range];
        
        if (count == 1)
        {
            NSString* duration = [dicItem objectForKey:@"duration"];
            interval = (NSTimeInterval)[duration doubleValue];
            *stop=YES;
        }
    }];
    return interval;
}

- (BOOL)setConfig:(NSString*) keyName AndValue:(NSString*) value
{
    if (!dicCacheConfig) {
        NSLog(@"Error ! dicCacheConfig is nil");
        return FALSE;
    }
    NSString* valueTmp = [dicCacheConfig objectForKey:keyName];
    if ( valueTmp!= nil)
    {
        [valueTmp stringByAppendingFormat:@"%@",value];
    }
    else
    {
        [dicCacheConfig setObject:value forKey:keyName];
    }
    
    return TRUE;
}

- (void)dealloc{
    [dicCacheConfig release];
    [arrConfig release];
    [super dealloc];
}
@end