/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloader.h"
#import "SDWebImageDecoder.h"
#import <ImageIO/ImageIO.h>

@interface SDWebImageDownloader (ImageDecoder) <SDWebImageDecoderDelegate,QLStaticDataFetcherDelegate>
@end

NSString *const SDWebImageDownloadStartNotification = @"SDWebImageDownloadStartNotification";
NSString *const SDWebImageDownloadStopNotification = @"SDWebImageDownloadStopNotification";

@interface SDWebImageDownloader ()
@property (nonatomic, retain) QLStaticDataFetcher *fetcher;
@end

@implementation SDWebImageDownloader
@synthesize url, delegate, fetcher=_fetcher, imageData, userInfo, lowPriority, progressive;

#pragma mark Public Methods

+ (id)downloaderWithURL:(NSURL *)url delegate:(id<SDWebImageDownloaderDelegate>)delegate
{
    return [self downloaderWithURL:url delegate:delegate userInfo:nil];
}

+ (id)downloaderWithURL:(NSURL *)url delegate:(id<SDWebImageDownloaderDelegate>)delegate userInfo:(id)userInfo
{
    return [self downloaderWithURL:url delegate:delegate userInfo:userInfo lowPriority:NO];
}

+ (id)downloaderWithURL:(NSURL *)url delegate:(id<SDWebImageDownloaderDelegate>)delegate userInfo:(id)userInfo lowPriority:(BOOL)lowPriority
{
    // Bind SDNetworkActivityIndicator if available (download it here: http://github.com/rs/SDNetworkActivityIndicator )
    // To use it, just add #import "SDNetworkActivityIndicator.h" in addition to the SDWebImage import
    if (NSClassFromString(@"SDNetworkActivityIndicator"))
    {
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id activityIndicator = [NSClassFromString(@"SDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
#pragma clang diagnostic pop

        // Remove observer in case it was previously added.
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStopNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:SDWebImageDownloadStopNotification object:nil];
    }

    SDWebImageDownloader *downloader = SDWIReturnAutoreleased([[SDWebImageDownloader alloc] init]);
    downloader.url = url;
    downloader.delegate = delegate;
    downloader.userInfo = userInfo;
    downloader.lowPriority = lowPriority;
    [downloader performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    return downloader;
}

+ (void)setMaxConcurrentDownloads:(NSUInteger)max
{
    // NOOP
}

- (void)start
{
    // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests
    self.fetcher = [QLStaticDataFetcher staticDataFetcherFromURLPath:[url absoluteString] httpHeaders:nil delegate:self];
    if (_fetcher)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStartNotification object:self];
    }
    else
    {
        if ([delegate respondsToSelector:@selector(imageDownloader:didFailWithError:)])
        {
            [delegate performSelector:@selector(imageDownloader:didFailWithError:) withObject:self withObject:nil];
        }
    }
}

- (void)cancel
{
    if (_fetcher)
    {
        [_fetcher cancel];
        self.fetcher = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:self];
    }
}

#pragma mark QLStaticDataFetcher (delegate)

- (void)staticDataFetcher:(QLStaticDataFetcher*)fetcher didReceiveResponse:(NSURLResponse*)response
{
    SDWIRetain(self);
    if (![response respondsToSelector:@selector(statusCode)] || [((NSHTTPURLResponse *)response) statusCode] < 400)
    {
        expectedSize = response.expectedContentLength > 0 ? (NSUInteger)response.expectedContentLength : 0;
        self.imageData = SDWIReturnAutoreleased([[NSMutableData alloc] initWithCapacity:expectedSize]);
    }
    else
    {
        [fetcher cancel];

        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];

        if ([delegate respondsToSelector:@selector(imageDownloader:didFailWithError:)])
        {
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain
                                                        code:[((NSHTTPURLResponse *)response) statusCode]
                                                    userInfo:nil];
            [delegate performSelector:@selector(imageDownloader:didFailWithError:) withObject:self withObject:error];
            SDWIRelease(error);
        }

        self.fetcher = nil;
        self.imageData = nil;
    }
    SDWIRelease(self);
}

- (void)staticDataFetcher:(QLStaticDataFetcher*)fetcher didReciveData:(NSData*)data downloadingProgressChanged:(float)progress
{
    SDWIRetain(self);
    [imageData appendData:data];

    if (CGImageSourceCreateImageAtIndex == NULL)
    {
        // ImageIO isn't present in iOS < 4
        self.progressive = NO;
    }

    if (self.progressive && expectedSize > 0 && [delegate respondsToSelector:@selector(imageDownloader:didUpdatePartialImage:)])
    {
        // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
        // Thanks to the author @Nyx0uf

        // Get the total bytes downloaded
        const NSUInteger totalSize = [imageData length];

        // Update the data source, we must pass ALL the data, not just the new bytes
        CGImageSourceRef imageSource = CGImageSourceCreateIncremental(NULL);
#if __has_feature(objc_arc)
        CGImageSourceUpdateData(imageSource, (__bridge  CFDataRef)imageData, totalSize == expectedSize);
#else
        CGImageSourceUpdateData(imageSource, (CFDataRef)imageData, totalSize == expectedSize);
#endif

        if (width + height == 0)
        {
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
            if (properties)
            {
                CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &height);
                val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &width);
                CFRelease(properties);
            }
        }

        if (width + height > 0 && totalSize < expectedSize)
        {
            // Create the image
            CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);

#ifdef TARGET_OS_IPHONE
            // Workaround for iOS anamorphic image
            if (partialImageRef)
            {
                const size_t partialHeight = CGImageGetHeight(partialImageRef);
                CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
                CGColorSpaceRelease(colorSpace);
                if (bmContext)
                {
                    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = partialHeight}, partialImageRef);
                    CGImageRelease(partialImageRef);
                    partialImageRef = CGBitmapContextCreateImage(bmContext);
                    CGContextRelease(bmContext);
                }
                else
                {
                    CGImageRelease(partialImageRef);
                    partialImageRef = nil;
                }
            }
#endif

            if (partialImageRef)
            {
                UIImage *image = SDScaledImageForPath(url.absoluteString, [UIImage imageWithCGImage:partialImageRef]);
                [[SDWebImageDecoder sharedImageDecoder] decodeImage:image
                                                       withDelegate:self
                                                           userInfo:[NSDictionary dictionaryWithObject:@"partial" forKey:@"type"]];

                CGImageRelease(partialImageRef);
            }
        }

        CFRelease(imageSource);
    }
    SDWIRelease(self);
}

#pragma GCC diagnostic ignored "-Wundeclared-selector"
- (void)staticDataFetcher:(QLStaticDataFetcher*)fetcher fetchedData:(NSData*)data
{
    SDWIRetain(self);
    [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];

    if ([delegate respondsToSelector:@selector(imageDownloaderDidFinish:)])
    {
        [delegate performSelector:@selector(imageDownloaderDidFinish:) withObject:self];
    }

    if ([delegate respondsToSelector:@selector(imageDownloader:didFinishWithImage:)])
    {
        UIImage *image = SDScaledImageForPath(url.absoluteString, imageData);
        [[SDWebImageDecoder sharedImageDecoder] decodeImage:image withDelegate:self userInfo:nil];
    }
    self.fetcher = nil;
    
    SDWIRelease(self);
}

- (void)staticDataFetcher:(QLStaticDataFetcher*)fetcher receivedError:(NSError*)error
{
    SDWIRetain(self);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];

    if ([delegate respondsToSelector:@selector(imageDownloader:didFailWithError:)])
    {
        [delegate performSelector:@selector(imageDownloader:didFailWithError:) withObject:self withObject:error];
    }

    self.fetcher = nil;
    self.imageData = nil;
    
    SDWIRelease(self);
}

#pragma mark SDWebImageDecoderDelegate

- (void)imageDecoder:(SDWebImageDecoder *)decoder didFinishDecodingImage:(UIImage *)image userInfo:(NSDictionary *)aUserInfo
{
    if ([[aUserInfo valueForKey:@"type"] isEqualToString:@"partial"])
    {
        [delegate imageDownloader:self didUpdatePartialImage:image];
    }
    else
    {
        [delegate performSelector:@selector(imageDownloader:didFinishWithImage:) withObject:self withObject:image];
    }
}

#pragma mark NSObject

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_fetcher cancel];
    self.fetcher=nil;
    SDWISafeRelease(url);
    SDWISafeRelease(imageData);
    SDWISafeRelease(userInfo);
    SDWISuperDealoc;
}


@end
