#import "BkFlutterImagePlugin.h"
#import "BkImageRenderWorker.h"

@interface BkFlutterImagePlugin ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, BkImageRenderWorker *> *workers;
@property (nonatomic, strong) NSObject <FlutterTextureRegistry> *textures;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation BkFlutterImagePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
    FlutterMethodChannel *channel = [FlutterMethodChannel
               methodChannelWithName:@"bk_flutter_image"
               binaryMessenger:[registrar messenger]];
       BkFlutterImagePlugin *instance = [[BkFlutterImagePlugin alloc] initWithTextures:[registrar textures]];
       [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithTextures:(NSObject <FlutterTextureRegistry> *)textures {
    self = [super init];
    if (self) {
        _workers = [[NSMutableDictionary alloc] init];
        _textures = textures;
        _queue = dispatch_queue_create("method_handler_queue", DISPATCH_QUEUE_SERIAL);

    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([@"create" isEqualToString:call.method]) {
            NSInteger __block textureId = -1;
            id <FlutterTextureRegistry> __weak registry = strongSelf.textures;
            BkImageRenderWorker *worker = [[BkImageRenderWorker alloc] initWithParams:[self convertToNoNullDic:call.arguments] onNewFrame:^(bool success) {
                [registry textureFrameAvailable:textureId];
            }];
            textureId = (NSInteger) [strongSelf.textures registerTexture:worker];
            [worker startWork];
            result(@(textureId));
        } else if ([@"dispose" isEqualToString:call.method]) {
            NSNumber *textureId = call.arguments[@"textureId"];
            if (![textureId isKindOfClass:[NSNull class]] && textureId.integerValue != -1) {
                [strongSelf.textures unregisterTexture:[textureId integerValue]];
            }
            result(nil);
        } else {
            result(FlutterMethodNotImplemented);
        }
    });
}

- (NSString *)stringFromDictionary:(NSDictionary *)dict {
    
    NSString *jsonString = nil;
    if ([NSJSONSerialization isValidJSONObject:dict]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        jsonString =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (error) {
            //return [self errorString:error];
        }
    }
    return jsonString;
}

- (NSDictionary *)convertToNoNullDic:(NSDictionary *)dic {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:dic.count];
    for (id key in dic.allKeys) {
        if (![dic[key] isEqual:[NSNull null]]){
            mDic[key] = dic[key];
        }
    }
    return mDic;
}

@end
