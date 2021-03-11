#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (BkFlutterFit)

- (UIImage *)bkfFill:(CGSize)size;
- (UIImage *)bkfContain:(CGSize)size;
- (UIImage *)bkfCover:(CGSize)size;
- (UIImage *)bkfFitWidth:(CGSize)size;
- (UIImage *)bkfFitHeight:(CGSize)size;
- (UIImage *)bkfFitNone:(CGSize)size;
- (UIImage *)bkfScaleDown:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
