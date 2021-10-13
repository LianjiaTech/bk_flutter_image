import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

typedef ImageCallback = void Function(ImageViewController controller);

class BkFlutterImage extends StatefulWidget {
  const BkFlutterImage({
    Key key,
    this.url,
    this.placeholder,
    this.width,
    this.height,
    // this.aspectRatio,
    this.loading = const CupertinoActivityIndicator(),
    this.imageFitMode = BoxFit.contain,
    this.centerCrop = true,
    this.autoResize = true,
  }) : super(key: key);

  final String url; // 图片web地址
  final Widget placeholder;
  final double width; // 组件宽度
  final double height; // 组件高度
  //final double aspectRatio; // 图片比例（从手机获取手机）
  final Widget loading; // loading
  final bool centerCrop; //是否剧中裁剪
  final BoxFit imageFitMode; // 图片显示模式
  final bool autoResize; // 是否下采样图片大小

  @override
  State<StatefulWidget> createState() => _BkFlutterImageState();
}

class _BkFlutterImageState extends State<BkFlutterImage> {
  ImageViewController _controller = ImageViewController();
  int textureId = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: (textureId < 0 && widget.placeholder != null)
          ? widget.placeholder
          : Texture(
              textureId: textureId,
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    updateTexture();
  }

  @override
  void didUpdateWidget(covariant BkFlutterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.dispose();
    _controller = ImageViewController();
    updateTexture();
  }

  void updateTexture() {
    _controller
        .initialize(widget.url,
            width: widget.width,
            height: widget.height,
            imageFitMode: widget.imageFitMode,
            autoResize: widget.autoResize,
            centerCrop: widget.centerCrop)
        .then((value) {
      setState(() {
        textureId = value;
      });
    });
  }

  @override
  void dispose() {
    //不加上这个会内存泄漏
    _controller.dispose();
    logger("_controller.dispose()");
    super.dispose();
  }
}

class ImageViewController {
  MethodChannel _channel = MethodChannel('bk_flutter_image');
  int textureId = -1;
  bool disposed = false;

  Future<dynamic> initialize(String url,
      {double width,
      double height,
      BoxFit imageFitMode = BoxFit.contain,
      bool autoResize = true,
      bool centerCrop = true}) async {
    textureId = await _channel.invokeMethod('create', {
      'width': width,
      'height': height,
      'url': url,
      'imageFitMode': imageFitMode.index,
      'autoResize': autoResize,
      'centerCrop': centerCrop
    });
    return Future.value(textureId);
  }

  void dispose() {
    logger('dispose $textureId');
    _channel.invokeMethod('dispose', {'textureId': textureId});
    disposed = true;
  }

  bool get isInitialized => textureId != null;
}

logger(dynamic msgs) {
  assert(() {
    debugPrint('[DEBUG] # $msgs');
    return true;
  }());
}
