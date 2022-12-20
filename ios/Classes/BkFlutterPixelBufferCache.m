//
//  BkFlutterPixelBufferCache.m
//  bk_flutter_image
//
//  Created by zhao hongwei on 2022/5/13.
//

#import "BkFlutterPixelBufferCache.h"

#import <Foundation/Foundation.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/SDWebImageDownloader.h>
#import <objc/runtime.h>
#import <SDWebImage/SDImageIOAnimatedCoder.h>
#import <SDWebImage/SDImageCoderHelper.h>

API_AVAILABLE(ios(10.0))
@interface BkFlutterPixelBufferCache ()

@property (nonatomic, strong) SDMemoryCache *cache;
@property (nonatomic, strong) SDDiskCache *diskCache;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation BkFlutterPixelBufferCache

#pragma init
+ (BkFlutterPixelBufferCache *)sharedInstance {
    static BkFlutterPixelBufferCache *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}


+ (void)swizzlingOriginClass:(Class)originClass originMethodName:(NSString *)originMethodName
                currentClass:(Class)currentClass currentMethodName:(NSString *)currentMethodName
{
    SEL originSelector = NSSelectorFromString(originMethodName);
    SEL currentSelector = NSSelectorFromString(currentMethodName);
    Method originMethod = class_getInstanceMethod(originClass, originSelector);
    Method currentMethod = class_getInstanceMethod(currentClass, currentSelector);
    BOOL isSwizzed = class_addMethod(originClass, originSelector, method_getImplementation(currentMethod), method_getTypeEncoding(currentMethod));
    if (isSwizzed) {
        class_replaceMethod(originClass, currentSelector,method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
    } else {
        method_exchangeImplementations(originMethod, currentMethod);
    }
}

- (id)init {
    if (self = [super init]) {
        SDImageCacheConfig *config = [SDImageCacheConfig new];
        self.diskCache = [[SDDiskCache alloc] initWithCachePath: [[SDImageCache defaultDiskCacheDirectory] stringByAppendingPathComponent:@"bkFlutterImage"] config:config];
        self.cache = [[SDMemoryCache alloc] initWithConfig:config];
        self.queue = dispatch_queue_create("com.BK.flutterImage", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)setMemoryCacheMaxSize:(NSUInteger)maxSize {
    self.cache.config.maxMemoryCost = maxSize * 1024 * 1024;
}

- (void)setDiskCacheMaxSize:(NSUInteger)maxSize {
    self.cache.config.maxDiskSize = maxSize * 1024 * 1024;
}

#pragma load
- (void)loadImageAndPixelBuffer:(NSString *)url size:(CGSize)size completion:(void (^)(BkFlutterPixelBufferRef *buffer, NSError* error, BOOL isFullPixel))completion {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.queue, ^{
        BOOL isFullPixel;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BkFlutterPixelBufferRef *bufferRef = [strongSelf pixelBufferRefWithUrl:url size:size isFullPixelImage:&isFullPixel];
        if (!bufferRef) {
            NSDictionary *context = CGSizeEqualToSize(size, CGSizeMake(-1, -1)) ? nil : @{SDWebImageContextImageThumbnailPixelSize:@(size)};
            
            //先检查缓存中的Image
            UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url];
            NSData *data;
            BOOL isFullPixel;
            if (memoryImage) {
                data = [[SDImageCache sharedImageCache] diskImageDataForKey:url];
                isFullPixel = [strongSelf isFullPixelImage:memoryImage data:data];
                if (isFullPixel || [strongSelf sizeMatch:memoryImage.size toSize:size]) {
                    [strongSelf handleResult:nil image:memoryImage url:url isFullPixel:isFullPixel error:nil completion:completion];
                    return;
                }
            }
            
            //检查diskImage
            UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:url options:0 context:context];
            if (diskImage) {
                if (context){
                    data = data ?: [[SDImageCache sharedImageCache] diskImageDataForKey:url];
                    isFullPixel = [strongSelf isFullPixelImage:diskImage data:data];
                } else {
                    isFullPixel = YES;
                }
                [strongSelf handleResult:nil image:diskImage url:url isFullPixel:isFullPixel error:nil completion:completion];
                return;
            }
            
            __weak typeof(self) weakSelf = strongSelf;
            [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[[NSURL alloc] initWithString:url] options:SDWebImageDownloaderScaleDownLargeImages | SDWebImageDownloaderUseNSURLCache | SDWebImageDownloaderAvoidDecodeImage context:context progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                dispatch_async(strongSelf.queue, ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (!error && image) {
                        [strongSelf handleResult:nil image:image url:url isFullPixel:[strongSelf isFullPixelImage:image data:data] error:error completion:completion];
                        [[SDImageCache sharedImageCache] storeImageDataToDisk:data forKey:url];
                    } else {
                        [strongSelf handleResult:nil image:nil url:url isFullPixel:NO error:error completion:completion];
                    }
                });
            }];
        } else if (completion) {
            [strongSelf handleResult:bufferRef image:nil url:url isFullPixel:isFullPixel error:nil completion:completion];
        }
    });
}


- (void)handleResult:(BkFlutterPixelBufferRef *)bufferRef image:(UIImage *)image url:(NSString *)url isFullPixel:(BOOL)isFullPixel error:(NSError *)error completion:(void (^)( BkFlutterPixelBufferRef *buffer, NSError* error, BOOL isFullPixel))completion  {
    bufferRef = bufferRef ?: [BkFlutterPixelBufferRef pixelBufferRefWithImage:image];
    [self storePixelBufferRef:bufferRef url:url isFullPixelImage:isFullPixel];
    if (completion)
        completion(bufferRef, error, isFullPixel);
}

#pragma memory op

- (BkFlutterPixelBufferRef *)pixelBufferRefWithUrl:(NSString *)url size:(CGSize)size isFullPixelImage:(BOOL *)isFullPixelImage{
    //get memory
    NSString *fullSizeCacheKey = [url stringByAppendingString:@"&BkFlutterFullSize"];
    BkFlutterPixelBufferRef *fullRef = [self.cache objectForKey:fullSizeCacheKey];
    BkFlutterPixelBufferRef *thumbRef = [self.cache objectForKey:url];
    if (fullRef || thumbRef) { //check memory
        CGSize pixelSize = fullRef ? CGSizeMake(INT_MAX, INT_MAX) : CGSizeMake(CVPixelBufferGetWidth(thumbRef.ref), CVPixelBufferGetHeight(thumbRef.ref));
        
        if ([self sizeMatch:pixelSize toSize:size]) {
            CGSize logSize = fullRef ? CGSizeMake(CVPixelBufferGetWidth(fullRef.ref), CVPixelBufferGetHeight(fullRef.ref)) : CGSizeMake(CVPixelBufferGetWidth(thumbRef.ref), CVPixelBufferGetHeight(thumbRef.ref));
            *isFullPixelImage = fullRef != nil;
            return fullRef ?:thumbRef;
        }
    } else { //check disk
        BkFlutterPixelBufferRef *diskRef = [self diskPixelBufferRefWithUrl:url size:size isFullPixelImage:isFullPixelImage];
        //store in menory cache
        [self storePixelBufferRef:diskRef url:url isFullPixelImage:*isFullPixelImage];
        return diskRef;
    }
    return nil;
}

- (void)storePixelBufferRef:(BkFlutterPixelBufferRef *)buffer url:(NSString *)url isFullPixelImage:(BOOL)isFullPixelImage {
    if (buffer == nil)
        return;
    CGSize targetSize = CGSizeMake(CVPixelBufferGetWidth(buffer.ref), CVPixelBufferGetHeight(buffer.ref));

    NSString *fullSizeCacheKey = [url stringByAppendingString:@"&BkFlutterFullSize"];
    NSString *targetCacheKey = isFullPixelImage ? fullSizeCacheKey : url;

    BkFlutterPixelBufferRef *fullRef = [self.cache objectForKey:fullSizeCacheKey];
    BkFlutterPixelBufferRef *thumbRef = [self.cache objectForKey:targetCacheKey];
    
    if (fullRef == buffer || thumbRef == buffer)
        return;
    
    if (!fullRef) {
        if (isFullPixelImage || !thumbRef) {
            [self.cache setObject:buffer forKey:targetCacheKey cost:targetSize.width * targetSize.height * 4];
            [self storeDiskPixelBufferRef:buffer url:url isFullPixelImage:isFullPixelImage];
        } else {
            CGSize thumbSize = CGSizeMake(CVPixelBufferGetWidth(thumbRef.ref), CVPixelBufferGetHeight(thumbRef.ref));
            if ([self sizeMatch:targetSize toSize:thumbSize]) {
                [self.cache setObject:buffer forKey:targetCacheKey cost:targetSize.width * targetSize.height * 4];
                [self storeDiskPixelBufferRef:buffer url:url isFullPixelImage:isFullPixelImage];
            }
        }
    }
}


#pragma disk op
- (BkFlutterPixelBufferRef *)diskPixelBufferRefWithUrl:(NSString *)url size:(CGSize)size isFullPixelImage:(BOOL *)isFullPixelImage {
    
    BkFlutterPixelBufferRef *ref = nil;
    BOOL tempIsFullPixelImage = NO;
    if ([self.diskCache containsDataForKey:url]) {
        NSData *data = [self.diskCache extendedDataForKey:url];
        NSError *error = nil;
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSDictionary *sizeDic = [unarchiver decodeObjectForKey:@"sizeInfo"];
        if (!error && sizeDic && sizeDic[@"PixelBufferSize"]) {
            CGSize pixelSize = [sizeDic[@"IsFullPixelImage"] boolValue] ? CGSizeMake(INT_MAX, INT_MAX) : [sizeDic[@"PixelBufferSize"] CGSizeValue];
            if ([self sizeMatch:pixelSize toSize:size]) {
                ref = [BkFlutterPixelBufferRef pixelBufferRefFromData:[self.diskCache dataForKey:url] size:[sizeDic[@"PixelBufferSize"] CGSizeValue]];
                tempIsFullPixelImage = [sizeDic[@"IsFullPixelImage"] boolValue];
            }
        }
    }

    *isFullPixelImage = tempIsFullPixelImage;
    return ref;
}

- (void)storeDiskPixelBufferRef:(BkFlutterPixelBufferRef *)buffer url:(NSString *)url isFullPixelImage:(BOOL)isFullPixelImage {
    dispatch_async(self.queue, ^{
        if (![self.diskCache containsDataForKey:url]) {
            //sizekey
            CGSize targetSize = CGSizeMake(CVPixelBufferGetWidth(buffer.ref), CVPixelBufferGetHeight(buffer.ref));
            NSMutableData *data = [[NSMutableData alloc]init];
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
            [archiver encodeObject:@{@"PixelBufferSize":@(targetSize),@"IsFullPixelImage":@(isFullPixelImage)}
                            forKey:@"sizeInfo"];
            [archiver finishEncoding];
            
            [self.diskCache setData:[BkFlutterPixelBufferRef dataFromPixelBufferRef:buffer] forKey:url];
            [self.diskCache setExtendedData:data forKey:url];
        }
    });
}

#pragma tool
- (BOOL)sizeMatch:(CGSize)size toSize:(CGSize)toSize {
    //前置处理
    size = [self convertSize:size];
    toSize = [self convertSize:toSize];

    CGFloat pixelRatio = size.width / size.height;
    CGFloat thumbnailRatio = toSize.width / toSize.height;

    if ((pixelRatio >= thumbnailRatio && size.width >= toSize.width)
        || (pixelRatio < thumbnailRatio && size.height >= toSize.height)) {
        return YES;
    }
    return NO;
}

- (CGSize)convertSize:(CGSize)size {
    CGFloat width =  size.width;
    CGFloat height =  size.height;

    if (width < 0 || height < 0) {
        width = INT_MAX;
        height = INT_MAX;
    }
    
    width = width == 0 ? 1 : width;
    height = height == 0 ? 1 : height;
    return CGSizeMake(width, height);
}

- (BOOL)isFullPixelImage:(UIImage *)image data:(NSData *)imageData {
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);

    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    double pixelWidth = [properties[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue];
    double pixelHeight = [properties[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
    CFRelease(source);
    return CGSizeEqualToSize(image.size, CGSizeMake(pixelWidth, pixelHeight));
}

//fix SDWebImage Bug
+ (UIImage *)createFrameAtIndex:(NSUInteger)index source:(CGImageSourceRef)source scale:(CGFloat)scale preserveAspectRatio:(BOOL)preserveAspectRatio thumbnailSize:(CGSize)thumbnailSize options:(NSDictionary *)options {
    // Some options need to pass to `CGImageSourceCopyPropertiesAtIndex` before `CGImageSourceCreateImageAtIndex`, or ImageIO will ignore them because they parse once :)
    // Parse the image properties
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, (__bridge CFDictionaryRef)options);
    double pixelWidth = [properties[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue];
    double pixelHeight = [properties[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
    CGImagePropertyOrientation exifOrientation = (CGImagePropertyOrientation)[properties[(__bridge NSString *)kCGImagePropertyOrientation] unsignedIntegerValue];
    if (!exifOrientation) {
        exifOrientation = kCGImagePropertyOrientationUp;
    }
    
    CFStringRef uttype = CGImageSourceGetType(source);
    // Check vector format
    BOOL isVector = NO;
    if ([NSData sd_imageFormatFromUTType:uttype] == SDImageFormatPDF) {
        isVector = YES;
    }

    NSMutableDictionary *decodingOptions;
    if (options) {
        decodingOptions = [NSMutableDictionary dictionaryWithDictionary:options];
    } else {
        decodingOptions = [NSMutableDictionary dictionary];
    }
    CGImageRef imageRef;
    BOOL createFullImage = thumbnailSize.width == 0 || thumbnailSize.height == 0 || pixelWidth == 0 || pixelHeight == 0 || (pixelWidth <= thumbnailSize.width && pixelHeight <= thumbnailSize.height);
    if (createFullImage) {
        if (isVector) {
            if (thumbnailSize.width == 0 || thumbnailSize.height == 0) {
                // Provide the default pixel count for vector images, simply just use the screen size
#if SD_WATCH
                thumbnailSize = WKInterfaceDevice.currentDevice.screenBounds.size;
#elif SD_UIKIT
                thumbnailSize = UIScreen.mainScreen.bounds.size;
#elif SD_MAC
                thumbnailSize = NSScreen.mainScreen.frame.size;
#endif
            }
            CGFloat maxPixelSize = MAX(thumbnailSize.width, thumbnailSize.height);
            NSUInteger DPIPerPixel = 2;
            NSUInteger rasterizationDPI = maxPixelSize * DPIPerPixel;
            decodingOptions[@"kCGImageSourceRasterizationDPI"] = @(rasterizationDPI);
        }
        imageRef = CGImageSourceCreateImageAtIndex(source, index, (__bridge CFDictionaryRef)[decodingOptions copy]);
    } else {
        decodingOptions[(__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform] = @(preserveAspectRatio);
        CGFloat maxPixelSize;
        if (preserveAspectRatio) {
            CGFloat pixelRatio = pixelWidth / pixelHeight;
            CGFloat thumbnailRatio = thumbnailSize.width / thumbnailSize.height;
            if (pixelRatio > thumbnailRatio) {
                maxPixelSize = MAX(thumbnailSize.width, thumbnailSize.width / pixelRatio);
            } else {
                maxPixelSize = MAX(thumbnailSize.height * pixelRatio, thumbnailSize.height);
            }
        } else {
            maxPixelSize = MAX(thumbnailSize.width, thumbnailSize.height);
        }
        decodingOptions[(__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize] = @(maxPixelSize);
        decodingOptions[(__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways] = @(YES);
        imageRef = CGImageSourceCreateThumbnailAtIndex(source, index, (__bridge CFDictionaryRef)[decodingOptions copy]);
    }
    if (!imageRef) {
        return nil;
    }
    // Thumbnail image post-process
    if (!createFullImage) {
        if (preserveAspectRatio) {
            // kCGImageSourceCreateThumbnailWithTransform will apply EXIF transform as well, we should not apply twice
            exifOrientation = kCGImagePropertyOrientationUp;
        } else {
            // `CGImageSourceCreateThumbnailAtIndex` take only pixel dimension, if not `preserveAspectRatio`, we should manual scale to the target size
            CGImageRef scaledImageRef = [SDImageCoderHelper CGImageCreateScaled:imageRef size:thumbnailSize];
            CGImageRelease(imageRef);
            imageRef = scaledImageRef;
        }
    }
    
#if SD_UIKIT || SD_WATCH
    UIImageOrientation imageOrientation = [SDImageCoderHelper imageOrientationFromEXIFOrientation:exifOrientation];
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:imageOrientation];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:exifOrientation];
#endif
    CGImageRelease(imageRef);
    return image;
}


@end

@implementation BkFlutterPixelBufferRef

+ (BkFlutterPixelBufferRef *)pixelBufferRefFromData:(NSData *)data size:(CGSize)size {
    NSDictionary *pixelAttributes = @{(NSString*)kCVPixelBufferIOSurfacePropertiesKey:@{}};

    CVPixelBufferRef pixelBuffer = NULL;

    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          size.width,
                                          size.height,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef)(pixelAttributes),
                                          &pixelBuffer);//kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,

    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    unsigned char *plane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    unsigned char *bytes = (unsigned char *)data.bytes;
    memcpy(plane, bytes, size.width * size.height * 4);

    if (result != kCVReturnSuccess) {
        return nil;
    }
    BkFlutterPixelBufferRef *buffer = [[BkFlutterPixelBufferRef alloc] initWithRef:pixelBuffer];
    CVPixelBufferRelease(pixelBuffer);
    return buffer;
}

+ (NSData *)dataFromPixelBufferRef:(BkFlutterPixelBufferRef *)pixelBufferRef {
    CVPixelBufferLockBaseAddress(pixelBufferRef.ref, 0);
    unsigned char* address = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(pixelBufferRef.ref, 0);

    int32_t width  = (int32_t)CVPixelBufferGetWidth(pixelBufferRef.ref);
    int32_t height = (int32_t)CVPixelBufferGetHeight(pixelBufferRef.ref);

    NSMutableData* data = [NSMutableData dataWithBytes:address length:height * width * 4];
    CVPixelBufferUnlockBaseAddress(pixelBufferRef.ref, 0);
    return data;
}

+ (BkFlutterPixelBufferRef *)pixelBufferRefWithImage:(UIImage *)sImage {
    if (sImage) {
        CGImageRef image = [sImage CGImage];
        GLuint width = (GLuint)CGImageGetWidth(image);
        GLuint height = (GLuint)CGImageGetHeight(image);
        CGSize size = CGSizeMake(width, height);
        BOOL hasAlpha = bkCGImageRefContainsAlpha(image);

        CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @(YES), kCVPixelBufferCGImageCompatibilityKey,
                                 @(YES), kCVPixelBufferCGBitmapContextCompatibilityKey,
                                 empty, kCVPixelBufferIOSurfacePropertiesKey, nil];

        CVPixelBufferRef pixelBuffer = NULL;
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef) options, &pixelBuffer);
        NSParameterAssert(status == kCVReturnSuccess && pixelBuffer != NULL);
        if (status != kCVReturnSuccess)
            return nil;

        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        void *pxdata = CVPixelBufferGetBaseAddress(pixelBuffer);
        NSParameterAssert(pxdata != NULL);

        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        uint32_t bitmapInfo = bkBitmapInfoWithPixelFormatType(kCVPixelFormatType_32BGRA, (bool)hasAlpha);
        CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbColorSpace, bitmapInfo);

        NSParameterAssert(context);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CFRelease(empty);
        CGColorSpaceRelease(rgbColorSpace);
        CGContextRelease(context);
        
        BkFlutterPixelBufferRef *buffer = [[BkFlutterPixelBufferRef alloc] initWithRef:pixelBuffer];
        CVPixelBufferRelease(pixelBuffer);
        return buffer;
    } else {
        return nil;
    }
}

- (id)initWithRef:(CVPixelBufferRef)ref {
    if (self == [super init]) {
        self.ref = ref;
        CVPixelBufferRetain(ref);

    }
    return self;
}

- (void)dealloc {
    CVPixelBufferRelease(self.ref);
}


static uint32_t bkBitmapInfoWithPixelFormatType(OSType inputPixelFormat, bool hasAlpha) {
    if (inputPixelFormat == kCVPixelFormatType_32BGRA) {
        uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
        if (!hasAlpha)
            bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host;
        return bitmapInfo;
    } else if (inputPixelFormat == kCVPixelFormatType_32ARGB) {
        return kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big;
    } else
        return 0;
}

static BOOL bkCGImageRefContainsAlpha(CGImageRef imageRef) {
    if (!imageRef) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone || alphaInfo == kCGImageAlphaNoneSkipFirst ||alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

@end


