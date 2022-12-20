import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class BkFlutterImageImpl extends StatefulWidget {
  const BkFlutterImageImpl({
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
  }) : super(key: key);

  static void registerWith(dynamic registrar) {}

  final String url; // 图片web地址
  final double? width; // 组件宽度
  final double? height; // 组件高度
  final String? placeholder;
  final BoxFit fit; // 图片显示模式
  final bool autoResize; // 是否下采样图片大小
  final double? cacheWidth; // 下采样的宽度
  final double? cacheHeight; // 下采样的高度
  final ImageErrorWidgetBuilder? imageErrorBuilder;

  @override
  State<StatefulWidget> createState() => _BkFlutterImageState();

  static void setCacheMaxSize(double diskMaxSize, double memoryMaxSize) {}
}

class _BkFlutterImageState extends State<BkFlutterImageImpl> {
  @override
  Widget build(BuildContext context) {
    // String? placeholder = widget.placeholder;

    // if (placeholder == null || placeholder == '') {
    return Image.network(
      widget.url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.cacheWidth?.toInt(),
      cacheHeight: widget.cacheHeight?.toInt(),
      errorBuilder: widget.imageErrorBuilder,
    );
    // } else {//web添加placeholder，动画有bug
    //   return FadeInImage.assetNetwork(
    //       placeholder: placeholder,
    //       image: widget.url,
    //       width: widget.width,
    //       height: widget.height,
    //       fit: widget.fit,
    //       imageCacheHeight: widget.cacheHeight?.toInt(),
    //       imageCacheWidth: widget.cacheWidth?.toInt(),
    //       imageErrorBuilder: widget.imageErrorBuilder);
    // }
  }
}
