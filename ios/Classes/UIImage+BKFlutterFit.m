#import "UIImage+BKFlutterFit.h"

@implementation UIImage (BkFlutterFit)

- (UIImage *)bkfFill:(CGSize)size {
    return self;
}

- (UIImage *)bkfContain:(CGSize)size {
    //横纵至少有一边填充size,对比原图宽高比和展示区域宽高比，得出哪一边填充
    return [self shouldFitWidth:size] ? [self bkfFitWidth:size] : [self bkfFitHeight:size];
}

- (BOOL)shouldFitWidth:(CGSize)size {
    CGImageRef image = self.CGImage;
    CGFloat width = (GLuint)CGImageGetWidth(image);
    CGFloat height = (GLuint)CGImageGetHeight(image);
    CGFloat scale = width/height;
    CGFloat boxScale = size.width/size.height;
    return scale > boxScale ? YES : NO;
}

- (UIImage *)bkfCover:(CGSize)size {
    return [self shouldFitWidth:size] ? [self bkfFitHeight:size] : [self bkfFitWidth:size];
}

- (UIImage *)bkfFitWidth:(CGSize)size {
    CGImageRef image = self.CGImage;
    CGFloat width = (GLuint)CGImageGetWidth(image);
    CGFloat height = (GLuint)CGImageGetHeight(image);
    //step1，求原图width与展示区域with比例
    CGFloat scale = size.width / width;
    //step2，求图片放大后的宽高,因为fitWidth，所以最终宽和展示区域一样大，只求高
    CGFloat newHeight = height * scale;
    //step3，放大后高度超过展示区高度，使用裁剪，否则使用上下填白
    if (newHeight >= size.height) { //裁剪
        CGFloat cropY = ((newHeight - size.height)/2 ) / scale;
        return [self imageByCropToRect:CGRectMake(0, cropY, width, height - cropY*2)];
    }else{
        CGFloat drawWidth = size.width / scale;
        CGFloat drawHeight = size.height / scale;
        CGFloat drawY = (drawHeight - height) / 2;
        return [self imageByDrawInSize:CGSizeMake(drawWidth, drawHeight) rect:CGRectMake(0, drawY, width, height)];
    }
}

- (UIImage *)bkfFitHeight:(CGSize)size
{
    CGImageRef image = self.CGImage;
    CGFloat width = (GLuint)CGImageGetWidth(image);
    CGFloat height = (GLuint)CGImageGetHeight(image);
    //step1，求原图height与展示区域height比例
    CGFloat scale = size.height / height;
    //step2，求图片放大后的宽高,因为fitWidth，所以最终宽和展示区域一样大，只求高
    CGFloat newWidth = width * scale;
    //step3，放大后高度超过展示区宽度，使用裁剪，否则使用左右填白
    if (newWidth >= size.width) { //裁剪
        CGFloat cropX = ((newWidth - size.width)/2 ) / scale;
        return [self imageByCropToRect:CGRectMake(cropX, 0, width - cropX*2, height)];
    }else{
        CGFloat drawWidth = size.width / scale;
        CGFloat drawHeight = size.height / scale;
        CGFloat drawX = (drawWidth - width) / 2;
        return [self imageByDrawInSize:CGSizeMake(drawWidth, drawHeight) rect:CGRectMake(drawX, 0, width, height)];
    }
}

- (UIImage *)bkfFitNone:(CGSize)size
{
    return self;
}

- (UIImage *)bkfScaleDown:(CGSize)size
{
    CGImageRef image = self.CGImage;
    CGFloat width = (GLuint)CGImageGetWidth(image);
    CGFloat height = (GLuint)CGImageGetHeight(image);
    if (size.width > width || size.height > height) {
        return [self bkfContain:size];
    }else{
        return self;
    }
}

//图片裁剪
- (UIImage *)imageByCropToRect:(CGRect)rect
{
    rect.origin.x *= self.scale;
    rect.origin.y *= self.scale;
    rect.size.width *= self.scale;
    rect.size.height *= self.scale; // pt -> px (point -> pixel)
    if (rect.size.width <= 0 || rect.size.height <= 0){
      return nil;
    }
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return image;
}

//图片补白
- (UIImage *)imageByDrawInSize:(CGSize)size rect:(CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    //draw
    [self drawInRect:rect];
    //capture resultant image
    UIImage *newimage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newimage;
}

@end
