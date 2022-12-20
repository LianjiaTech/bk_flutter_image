#import "BkFlutterImagePlugin.h"
#import "BkImageRenderWorker.h"
#import "BkFlutterPixelBufferCache.h"


@interface BkFlutterImagePlugin ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, BkImageRenderWorker *> *workers;
@property (nonatomic, weak) NSObject <FlutterTextureRegistry> *textures;

@end

@implementation BkFlutterImagePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar{
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
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"create" isEqualToString:call.method]) {
        NSInteger __block textureId = -1;
        id <FlutterTextureRegistry> __weak registry = self.textures;
        BkImageRenderWorker *worker = [[BkImageRenderWorker alloc] initWithParams:[self convertToNoNullDic:call.arguments] onNewFrame:^(NSError * error, CGSize size, BOOL isFullPixel) {
            NSMutableDictionary *textureInfo = [NSMutableDictionary dictionary];
            [textureInfo setValue:error.userInfo[NSLocalizedDescriptionKey] ?: @"" forKey:@"error"];
            [textureInfo setValue:@(error ? -1 : textureId) forKey:@"textureId"];
            [textureInfo setValue:@(size.width) forKey:@"textureWidth"];
            [textureInfo setValue:@(size.height) forKey:@"textureHeight"];
            [textureInfo setValue:@(isFullPixel) forKey:@"isFullPixel"];
            result([[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:textureInfo options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding]);
            [registry textureFrameAvailable:textureId];
        }];
        textureId = (NSInteger) [self.textures registerTexture:worker];
        [worker startWork];
    } else if ([@"dispose" isEqualToString:call.method]) {
        NSNumber *textureId = call.arguments[@"textureId"];
        if (![textureId isKindOfClass:[NSNull class]] && textureId.integerValue != -1) {
            [self.textures unregisterTexture:[textureId integerValue]];
        }
        result(nil);
    } else if ([@"setCacheSize" isEqualToString:call.method]) {
        NSDictionary *cacheData = [self convertToNoNullDic:call.arguments];
        [[BkFlutterPixelBufferCache sharedInstance] setDiskCacheMaxSize:[cacheData[@"diskMaxSize"] unsignedIntValue]];
        [[BkFlutterPixelBufferCache sharedInstance] setMemoryCacheMaxSize:[cacheData[@"memoryMaxSize"] unsignedIntValue]];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
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
