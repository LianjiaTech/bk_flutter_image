#import <FLutter/FlutterTexture.h>

@interface BkImageRenderWorker : NSObject <FlutterTexture>

@property (nonatomic, assign) BOOL glInitDone;
@property (nonatomic, assign) BOOL disposed;

- (instancetype)initWithParams:(NSDictionary *)params onNewFrame:(void (^)(bool success))onNewFrame;
- (void)startWork;
@end
