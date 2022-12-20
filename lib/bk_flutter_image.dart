import 'package:flutter/cupertino.dart';

import 'package:bk_flutter_image/bk_flutter_image_native.dart'
    if (dart.library.html) 'package:bk_flutter_image/bk_flutter_image_web.dart';

class BkFlutterImage extends BkFlutterImageImpl {
  const BkFlutterImage({
    Key? key,
    required this.url,
    this.placeholder,
    this.width,
    this.height,
    this.fit = BoxFit.none,
    this.autoResize = true,
    this.cacheWidth,
    this.cacheHeight,
    this.imageErrorBuilder,
  }) : super(
            key: key,
            url: url,
            placeholder: placeholder,
            width: width,
            height: height,
            fit: BoxFit.none,
            autoResize: true,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            imageErrorBuilder: imageErrorBuilder);

  final String url; // 图片web地址
  final double? width; // 组件宽度
  final double? height; // 组件高度
  final String? placeholder;
  final BoxFit fit; // 图片显示模式
  final bool autoResize; // 是否下采样图片大小
  final double? cacheWidth; // 下采样的宽度
  final double? cacheHeight; // 下采样的高度
  final ImageErrorWidgetBuilder? imageErrorBuilder;

  static void setCacheMaxSize(double diskMaxSize, double memoryMaxSize) {
    BkFlutterImageImpl.setCacheMaxSize(diskMaxSize, memoryMaxSize);
  }
}
