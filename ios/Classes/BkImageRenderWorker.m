
#import "BkImageRenderWorker.h"

#import <UIKit/UIScreen.h>

#import "UIImageView+WebCache.h"
#import "SDWebImageDownloader.h"
#import "SDImageCache.h"

#import "UIImage+BKFlutterFit.h"

typedef NS_ENUM(NSUInteger, BeiKeBoxFit) {
    BeiKeBoxFitFill = 0,
    BeiKeBoxFitContain = 1,
    BeiKeBoxFitCover = 2,
    BeiKeBoxFitWidth = 3,
    BeiKeBoxFitHeight = 4,
    BeiKeBoxFitNone = 5,
    BeiKeBoxFitScaleDown = 6,
};

@interface BkImageRenderWorker ()

@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) CGFloat aspectRatio;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat widthPixel;
@property (nonatomic, assign) CGFloat heightPixel;
@property (nonatomic, assign) BOOL centerCrop;
@property (nonatomic, assign) BOOL autoResize;
@property (nonatomic, assign) BeiKeBoxFit imageFitMode;
@property (nonatomic, copy) void (^onNewFrame)(bool success);

@property (nonatomic, strong) UIImage *image;

@end

@implementation BkImageRenderWorker

- (instancetype)initWithParams:(NSDictionary *)params onNewFrame:(void (^)(bool success))onNewFrame {
    self = [super init];

    if (self) {
        _onNewFrame = onNewFrame;
        [self initParams:params];
    }

    return self;
}

- (void)initParams:(NSDictionary *)params {
    _url = params[@"url"];
    _aspectRatio = [[UIScreen mainScreen] scale];

    if (params[@"width"])
        _width = [params[@"width"] floatValue] * _aspectRatio;

    if (params[@"height"])
        _height = [params[@"height"] floatValue] * _aspectRatio;

    if (params[@"widthPixel"])
        _widthPixel = [params[@"widthPixel"] floatValue] * _aspectRatio;;

    if (params[@"heightPixel"])
        _heightPixel = [params[@"heightPixel"] floatValue] * _aspectRatio;

    if (params[@"centerCrop"])
        _centerCrop = [params[@"centerCrop"] boolValue];;

    if (params[@"imageFitMode"])
        _imageFitMode = [params[@"imageFitMode"] integerValue];;

    if (params[@"autoResize"])
        _autoResize = [params[@"autoResize"] boolValue];
}

- (void)startWork{
    
    NSDictionary *context = _autoResize ? @{SDWebImageContextImageThumbnailPixelSize:@(CGSizeMake(_width, _height))}: NULL;
    UIImage *image = [[SDImageCache sharedImageCache] imageFromCacheForKey:self.url options:0 context:context];
    
    if (!image) {
        __weak typeof(self) weakSelf = self;
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[[NSURL alloc] initWithString:self.url] options:SDWebImageDownloaderScaleDownLargeImages | SDWebImageDownloaderUseNSURLCache | SDWebImageDownloaderAvoidDecodeImage context:context progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!error && image) {
                [strongSelf callImage:[strongSelf convertImage:image]];
                [[SDImageCache sharedImageCache] storeImage:image forKey:strongSelf.url completion:nil];
            } else {
                [strongSelf callImage:nil];
            }
        }];
    } else {
        [self callImage:image];
    }
}

- (void)callImage:(UIImage *)image {
    self.image = image;
    bool success = self.image ? YES : NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.onNewFrame(success);
    });
}

- (UIImage *)convertImage:(UIImage *)image {
    if (!image) return nil;

    CGSize size = CGSizeMake(_width, _height);
    switch (_imageFitMode) {
        case BeiKeBoxFitFill:
            return [image bkfFill:size];
            break;
        case BeiKeBoxFitContain:
            return [image bkfContain:size];
            break;
        case BeiKeBoxFitCover:
            return [image bkfCover:size];
            break;
        case BeiKeBoxFitWidth:
            return [image bkfFitWidth:size];
            break;
        case BeiKeBoxFitHeight:
            return [image bkfFitHeight:size];
            break;
        case BeiKeBoxFitNone:
            return [image bkfFitNone:size];
        case BeiKeBoxFitScaleDown:
            return [image bkfScaleDown:size];
            break;
        default:
            return [image bkfFill:size];
            break;
    }
    return image;
}

#pragma mark - FlutterTexture

- (CVPixelBufferRef)copyPixelBuffer{
    return [self bkf_CVPixelBufferRef];
}

- (void)onTextureUnregistered:(NSObject<FlutterTexture>*)texture {
    _image = nil;
}

#pragma mark - Private

static OSType bkf_inputPixelFormat() {
    return kCVPixelFormatType_32BGRA;
}

static uint32_t bkf_bitmapInfoWithPixelFormatType(OSType inputPixelFormat, bool hasAlpha) {
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

BOOL bkf_CGImageRefContainsAlpha(CGImageRef imageRef) {
    if (!imageRef) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone || alphaInfo == kCGImageAlphaNoneSkipFirst ||alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

- (CVPixelBufferRef)bkf_CVPixelBufferRef
{
    if (_image) {
        CGImageRef image = [_image CGImage];
        GLuint width = (GLuint)CGImageGetWidth(image);
        GLuint height = (GLuint)CGImageGetHeight(image);
        CGSize size = CGSizeMake(width, height);
        BOOL hasAlpha = bkf_CGImageRefContainsAlpha(image);

        CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @(YES), kCVPixelBufferCGImageCompatibilityKey,
                                 @(YES), kCVPixelBufferCGBitmapContextCompatibilityKey,
                                 empty, kCVPixelBufferIOSurfacePropertiesKey, nil];

        CVPixelBufferRef pxbuffer = NULL;
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, bkf_inputPixelFormat(), (__bridge CFDictionaryRef) options, &pxbuffer);
        NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

        CVPixelBufferLockBaseAddress(pxbuffer, 0);
        void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
        NSParameterAssert(pxdata != NULL);

        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        uint32_t bitmapInfo = bkf_bitmapInfoWithPixelFormatType(bkf_inputPixelFormat(), (bool)hasAlpha);
        CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace, bitmapInfo);

        NSParameterAssert(context);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
        CFRelease(empty);
        CGColorSpaceRelease(rgbColorSpace);
        CGContextRelease(context);
        return pxbuffer;
    } else {
        return NULL;
    }
}

- (void)dealloc {
    NSLog(@"BkImageRenderWorker---dealloc");
}

@end
