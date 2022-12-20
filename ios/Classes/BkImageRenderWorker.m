
#import "BkImageRenderWorker.h"

#import <UIKit/UIScreen.h>

#import "UIImageView+WebCache.h"
#import "SDWebImageDownloader.h"
#import "SDImageCache.h"
#import "BkFlutterPixelBufferCache.h"

@interface BkImageRenderWorker ()

@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) CGFloat aspectRatio;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat widthPixel;
@property (nonatomic, assign) CGFloat heightPixel;
@property (nonatomic, assign) BOOL autoResize;
@property (nonatomic, copy) void (^onNewFrame)(NSError* error, CGSize size, BOOL isFullPixel);
@property (nonatomic, strong) BkFlutterPixelBufferRef *pixelBufferRef;

@end

@implementation BkImageRenderWorker

- (instancetype)initWithParams:(NSDictionary *)params onNewFrame:(void (^)(NSError* error, CGSize size, BOOL isFullPixel))onNewFrame {
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
    if (params[@"autoResize"])
        _autoResize = [params[@"autoResize"] boolValue];

    if (params[@"width"] && params[@"height"]) {
        //图片像素值没有小数
        _width =  floor([params[@"width"] floatValue] * _aspectRatio);
        _height = floor([params[@"height"] floatValue] * _aspectRatio);
    } else {
        _width = -1;
        _height = -1;
    }

}

- (void)startWork{
    __weak typeof(self) weakSelf = self;
    [[BkFlutterPixelBufferCache sharedInstance] loadImageAndPixelBuffer:self.url size:_autoResize ? CGSizeMake(_width, _height) : CGSizeMake(-1, -1) completion:^(BkFlutterPixelBufferRef * _Nonnull buffer, NSError* error, BOOL isFullPixel) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf callBufferRef:buffer isFullPixel:isFullPixel error:error];
    }];
}

- (void)callBufferRef:(BkFlutterPixelBufferRef *)buffer isFullPixel:(BOOL)isFullPixel error:(NSError *)error{
    if (buffer && !error) {
        self.pixelBufferRef = buffer;
        CGSize size = CGSizeMake(CVPixelBufferGetWidth(buffer.ref) / _aspectRatio, CVPixelBufferGetHeight(buffer.ref) / _aspectRatio);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.onNewFrame(nil, size,isFullPixel);
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.onNewFrame(error, CGSizeZero, isFullPixel);
        });
    }
}


#pragma mark - FlutterTexture

- (CVPixelBufferRef)copyPixelBuffer{
    if (self.pixelBufferRef) {
        CVPixelBufferRetain(self.pixelBufferRef.ref);
        return self.pixelBufferRef.ref;
    } else {
        return NULL;
    }
}

- (void)onTextureUnregistered:(NSObject<FlutterTexture>*)texture {
    _pixelBufferRef = nil;
}

@end
