//
//  BkFlutterPixelBufferCache.h
//  bk_flutter_image
//
//  Created by zhao hongwei on 2022/5/13.
//

#import <Foundation/Foundation.h>
#import "SDMemoryCache.h"
#import "SDImageCacheConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface BkFlutterPixelBufferRef : NSObject

@property (nonatomic, unsafe_unretained) CVPixelBufferRef ref;

+ (BkFlutterPixelBufferRef *)pixelBufferRefFromData:(NSData *)data size:(CGSize)size;
+ (BkFlutterPixelBufferRef *)pixelBufferRefWithImage:(UIImage *)sImage;

+ (NSData *)dataFromPixelBufferRef:(BkFlutterPixelBufferRef *)pixelBufferRef;

- (id)initWithRef:(CVPixelBufferRef)ref;

@end

@interface BkFlutterPixelBufferCache : NSObject

+ (instancetype)sharedInstance;

- (void)loadImageAndPixelBuffer:(NSString *)url size:(CGSize)size completion:(void (^)(BkFlutterPixelBufferRef *buffer, NSError* error, BOOL isFullPixel))completion;

- (void)setMemoryCacheMaxSize:(NSUInteger)maxSize;

- (void)setDiskCacheMaxSize:(NSUInteger)maxSize;

@end

NS_ASSUME_NONNULL_END
