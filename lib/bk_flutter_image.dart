import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ImageCallback = void Function(ImageViewController controller);

class BkFlutterImage extends StatefulWidget {
  const BkFlutterImage({
    Key key,
    this.url,
    this.width,
    this.height,
    // this.aspectRatio,
    this.loading = const CupertinoActivityIndicator(),
    this.imageFitMode = BoxFit.contain,
    this.centerCrop = true,
    this.placeholder,
    this.autoResize = true,
  }) : super(key: key);

  final String url; // 图片web地址
  final double width; // 组件宽度
  final double height; // 组件高度
  //final double aspectRatio; // 图片比例（从手机获取手机）
  final Widget loading; // loading
  final Widget placeholder;
  final bool centerCrop; //是否剧中裁剪
  final BoxFit imageFitMode; // 图片显示模式
  final bool autoResize; // 是否下采样图片大小

  @override
  State<StatefulWidget> createState() => _BkFlutterImageState();
}

class _BkFlutterImageState extends State<BkFlutterImage> {
  ImageViewController _controller;
  int textureId = -1;

  @override
  Widget build(BuildContext context) {
    return Texture(
      textureId: textureId,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = new ImageViewController.withUrl(widget.url, (_controller) {
      setState(() {
        textureId = _controller.textureId;
      });
    });
    _controller.initialize(
        width: widget.width,
        height: widget.height,
        imageFitMode: widget.imageFitMode,
        autoResize: widget.autoResize,
        centerCrop: widget.centerCrop);
  }

  @override
  void dispose() {
    //不加上这个会内存泄漏
    _controller.dispose();
    super.dispose();
  }
}

class ImageViewController {
  MethodChannel _channel = MethodChannel('bk_flutter_image');
  int textureId = -1;
  String url;
  bool disposed = false;
  ImageCallback onImageViewCreated;

  ImageViewController.withUrl(String url, ImageCallback onImageViewCreated) {
    this.url = url;
    this.onImageViewCreated = onImageViewCreated;
  }

  Future initialize(
      {double width,
      double height,
      BoxFit imageFitMode = BoxFit.contain,
      bool autoResize = true,
      bool centerCrop = true}) async {
    textureId = await _channel.invokeMethod('create', {
      'width': width,
      'height': height,
      'url': this.url,
      'imageFitMode': imageFitMode.index,
      'autoResize': autoResize,
      'centerCrop': centerCrop
    });

    if (disposed) {
      this.dispose();
    } else {
      this.onImageViewCreated(this);
    }
  }

  void dispose() {
    _channel.invokeMethod('dispose', {'textureId': textureId});
    disposed = true;
  }

  bool get isInitialized => textureId != null;
}
