import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

typedef ImageCallback = void Function(ImageViewController controller);
typedef SizeCallBack = void Function(Size size);

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
    this.color
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
  final Color? color;

  @override
  State<StatefulWidget> createState() => _BkFlutterImageState();

  static void setCacheMaxSize(double diskMaxSize, double memoryMaxSize) {
    ImageViewController.setCacheMaxSize(diskMaxSize, memoryMaxSize);
  }
}

class _BkFlutterImageState extends State<BkFlutterImageImpl> {
  ImageViewController _controller = ImageViewController();
  int textureId = -1;
  Object? error;

  bool isFullPixel = false;
  double textureWidth = -1;
  double textureHeight = -1;
  String textureUrl = '';
  bool textureAutoResize = true;

  Size? realSize;

  @override
  Widget build(BuildContext context) {
    List<LayoutId> idList = List.empty(growable: true);
    idList.add( LayoutId( id: _LayoutType.None,
        child: Container(color: widget.color ?? Color.fromARGB(0, 0, 0, 0))));
    _LayoutType layoutType = _LayoutType.None;
    if (textureId != -1) {
      idList.add(LayoutId(id: _LayoutType.Image, child: Texture(textureId: textureId)));
      layoutType = _LayoutType.Image;
    } else if (error != null && widget.imageErrorBuilder != null) {
      idList.add(LayoutId(id: _LayoutType.Error, child: widget.imageErrorBuilder!(context, error!, null)));
      layoutType = _LayoutType.Error;
    } else if (error == null && widget.placeholder != null) {
      idList.add(LayoutId(
          id: _LayoutType.PlaceHolder,
          child: Image.asset(
            widget.placeholder!,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
          )));
      layoutType = _LayoutType.PlaceHolder;
    }
    return _BkFlutterImageRenderObjectWidget(
      layoutType: layoutType,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      callBack: sizeChange,
      imageSize: Size(textureWidth,textureHeight),
      children: idList,);
  }

  @override
  void initState() {
    super.initState();
    if (widget.cacheWidth != null && widget.cacheHeight != null) {
      updateTexture();
    }
  }

  @override
  void didUpdateWidget(covariant BkFlutterImageImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (maybeUpdate(widget, null)) {
      updateTexture();
    }
  }

  void sizeChange(Size size) {
    Size? tempRealSize = size == Size(double.infinity,double.infinity) ?
              null : Size(size.width == double.infinity ? size.height : size.width, size.height == double.infinity ? size.width : size.height);
    if (tempRealSize == realSize) {
      return;
    }
    realSize = tempRealSize;
    if (maybeUpdate(widget, size)) {
      updateTexture();
    }
  }

  bool maybeUpdate(BkFlutterImageImpl newImage, Size? realSize) {
    if (textureUrl != newImage.url || textureId == -1) {
      return true;
    }
    //计算现有size
    Size oldSize = isFullPixel
        ? Size(double.maxFinite, double.maxFinite)
        : Size(textureWidth, textureHeight);

    Size requestSize =
        (newImage.cacheWidth != null && newImage.cacheHeight != null)
            ? Size(newImage.cacheWidth!, newImage.cacheHeight!)
            : realSize != null
                ? realSize
                : Size(0.1, 0.1);
    Size newSize = newImage.autoResize
        ? requestSize
        : Size(double.maxFinite, double.maxFinite);

    if (sizeMatchSize(oldSize, newSize)) {
      return false;
    }
    return true;
  }

  bool sizeMatchSize(Size fromSize, Size toSize) {
    double oldImageRatio = fromSize.width / fromSize.height;
    double newImageRatio = toSize.width / toSize.height;

    if (oldImageRatio >= newImageRatio && fromSize.width >= toSize.width ||
        oldImageRatio < newImageRatio && fromSize.height >= toSize.height) {
      return true;
    }

    return false;
  }

  void updateTexture() {
    print("updateTexture");

    _controller.dispose();
    _controller = ImageViewController();
    _controller
        .initialize(widget.url,
            width: widget.cacheWidth ?? realSize?.width,
            height: widget.cacheHeight ?? realSize?.height,
            autoResize: widget.autoResize)
        .then((value) {
      if (mounted) {
        setState(() {
          if (value != null) {
            textureId = value['textureId'];
            textureWidth =
                textureId == -1 ? -1 : value['textureWidth'].roundToDouble();
            textureHeight =
                textureId == -1 ? -1 : value['textureHeight'].roundToDouble();
            isFullPixel = value['isFullPixel'];
            error = value['error'].toString().isNotEmpty
                ? value['error'].toString()
                : (textureId == -1 ? '注册纹理失败' : null);
            textureAutoResize = widget.autoResize;
            textureUrl = widget.url;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    //不加上这个会内存泄漏
    _controller.dispose();
    print("_controller.dispose()");
    super.dispose();
  }
}

class ImageViewController {
  static MethodChannel _channel = MethodChannel('bk_flutter_image');
  bool disposed = false;
  int textureId = -1;

  Future<dynamic> initialize(String url,
      {double? width, double? height, bool autoResize = true}) async {
    String mapString = await _channel.invokeMethod('create', {
      'width': width,
      'height': height,
      'url': url,
      'autoResize': autoResize,
    });
    Map textureInfo = json.decode(mapString);
    textureId = textureInfo['textureId'];
    return Future.value(textureInfo);
  }

  void dispose() {
    logger('dispose $textureId');
    _channel.invokeMethod('dispose', {'textureId': textureId});
    disposed = true;
  }

  static void setCacheMaxSize(double diskMaxSize, double memoryMaxSize) {
    _channel.invokeMethod('setCacheSize',
        {'memoryMaxSize': memoryMaxSize, 'diskMaxSize': diskMaxSize});
  }
}


enum _LayoutType { None, PlaceHolder, Image, Error}

class _BkFlutterImageRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {

  SizeCallBack callBack;
  BoxFit _fit;
  Size _imageSize;
  double? _width;
  double? _height;
  Offset? imageOffset;

  _LayoutType layoutType = _LayoutType.None;


  _BkFlutterImageRenderObject({required this.layoutType,
    required Size imageSize,
    required this.callBack,
    required BoxFit fit,
    double? width,
    double? height,
    children,}): _imageSize = imageSize ,
  _fit = fit,
  _width = width,
  _height = height{
    addAll(children);
  }


  set fit(BoxFit fit) {
    if ( fit == _fit)
      return;
    _fit = fit;
    markNeedsLayout();
  }

  set imageSize(Size imageSize) {
    if ( imageSize == _imageSize)
      return;
    _imageSize = imageSize;
    markNeedsLayout();
  }

  set width(double? width) {
    if ( width == _width)
      return;
    _width = width;
    markNeedsLayout();
  }

  set height(double? height) {
    if ( height == _height)
      return;
    _height = height;
    markNeedsLayout();
  }

  Size get imageSize => _imageSize;
  BoxFit get fit => _fit;
  double? get height => _height;
  double? get width => _width;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData)
      child.parentData = MultiChildLayoutParentData();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
    );
  }

  Size calculateImageContainerSize(BoxConstraints c) {
    if (imageSize.width > 0 && imageSize.height > 0) {
      //1.计算逻辑，确定宽高是否都是范围值
      double? realWidth = c.minWidth == c.maxWidth ? c.maxWidth : null;
      double? realHeight = c.minHeight == c.maxHeight ? c.maxHeight : null;
      if (realHeight != null || realWidth != null) {
        //2.宽不是范围值，就采用宽，如果是则通过高计算，同理高也一样。
        realWidth =
            realWidth ?? imageSize.width / imageSize.height * realHeight!;
        realHeight =
            realHeight ?? imageSize.height / imageSize.width * realWidth;
      } else if (constraints.isSatisfiedBy(imageSize)) {
        //3.宽和搞都是范围值，并且image的大小都在这个范围内，那就直接采用image的大小
        realWidth = imageSize.width;
        realHeight = imageSize.height;
      } else if (c.minWidth < imageSize.width &&
          imageSize.width <= c.maxWidth) {
        //4.宽和搞都是范围值，但是高不在范围内，那么就把高直接换算成范围边界的就近值，然后宽按照比例计算宽。
        realHeight = c.constrainHeight(imageSize.height);
        realWidth = imageSize.width / imageSize.height * realHeight;
      } else if (c.minHeight < imageSize.height &&
          imageSize.height <= c.maxHeight) {
        //4.宽和搞都是范围值，但是宽不在范围内，那么就把宽直接换算成范围边界的就近值，然后高按照比例计算宽。
        realWidth = c.constrainWidth(imageSize.width);
        realHeight = imageSize.height / imageSize.width * realWidth;
      } else {
        //5.如果都不满足，那么就取值各自范围的Max，如果是无穷大，则取最小值。
        realWidth = c.maxWidth == double.infinity ? c.minWidth : c.maxWidth;
        realHeight = c.maxHeight == double.infinity ? c.minHeight : c.maxHeight;
      }
      return Size(realWidth,realHeight);
    }
    return Size.zero;
  }

  Size calculateImageContentSize(Size size){
    if (imageSize.width > 0 &&
        imageSize.height > 0) {
      Size realSize = imageSize;
      double wRatio = size.width / imageSize.width;
      double hRatio = size.height / imageSize.height;
      switch (fit) {
        case BoxFit.contain:
          if (wRatio <= hRatio) {
            realSize = Size(size.width, imageSize.height * wRatio);
          } else {
            realSize = Size(imageSize.width * hRatio, size.height);
          }
          break;
        case BoxFit.cover:
          if (wRatio >= hRatio) {
            realSize = Size(size.width, imageSize.height * wRatio);
          } else {
            realSize = Size(imageSize.width * hRatio, size.height);
          }
          break;
        case BoxFit.fitWidth:
          realSize = Size(size.width, imageSize.height * wRatio);
          break;
        case BoxFit.fitHeight:
          realSize = Size(imageSize.width * hRatio, size.height);
          break;
        case BoxFit.scaleDown:
          if (wRatio < 1 || hRatio < 1) {
            if (wRatio <= hRatio) {
              realSize = Size(size.width, imageSize.height * wRatio);
            } else {
              realSize = Size(imageSize.width * hRatio, size.height);
            }
          } else {
            realSize = imageSize;
          }
          break;
        case BoxFit.fill:
          realSize = size;
          break;
        case BoxFit.none:
          realSize = imageSize;
          break;
      }
      return realSize;
    }
    return Size.zero;
  }

  @override
  void performLayout() {
    Map<Object, RenderBox> idToChild = <Object, RenderBox>{};
    RenderBox? child = firstChild;
    while (child != null) {
      final MultiChildLayoutParentData childParentData = child.parentData! as MultiChildLayoutParentData;
      idToChild[childParentData.id!] = child;
      child = childParentData.nextSibling;
    }

    //根据限定大小，计算出新的约束
    BoxConstraints c = constraints.tighten(width: width, height: height);

    //根据约束情况返回请求信息
    if (layoutType != _LayoutType.Error) {
      callBack(c.biggest);
    }
    //开始实际布局，
    Size tempSize = Size.zero;
    imageOffset = null;
    switch (layoutType) {
      case _LayoutType.PlaceHolder:
        { //布局完成placeholder
          RenderBox? content = idToChild[_LayoutType.PlaceHolder];
          if (content != null) {
            content.layout(c, parentUsesSize: true);
            tempSize = content.size;
          }
        }
        break;
      case _LayoutType.Error:
        {
          RenderBox? content = idToChild[_LayoutType.Error];
          if (content != null) {
            content.layout(c, parentUsesSize: true);
            tempSize = content.size;
          }
        }
        break;
      case _LayoutType.Image:
        {
          RenderBox? content = idToChild[_LayoutType.Image];
          if (content != null) {
            tempSize = calculateImageContainerSize(c);
            Size imageContentSize = calculateImageContentSize(tempSize);
            content.layout(BoxConstraints.tight(imageContentSize));
            final MultiChildLayoutParentData childParentData = content
                .parentData! as MultiChildLayoutParentData;
            childParentData.offset = Offset((tempSize.width - imageContentSize.width) / 2,
                (tempSize.height - imageContentSize.height) / 2);
            imageOffset = childParentData.offset;
          }
        }
    }

    tempSize = Size (tempSize.width == double.infinity ? 0 : tempSize.width, tempSize.height == double.infinity ? 0 : tempSize.height);
    RenderBox? content = idToChild[_LayoutType.None];
    if (content != null) {
      content.layout(c,parentUsesSize: false);
    }
    size = tempSize;
  }


  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result as BoxHitTestResult, position: position);
  }
}

class _BkFlutterImageRenderObjectWidget extends MultiChildRenderObjectWidget {

  final SizeCallBack callBack;
  final BoxFit fit;
  final Size imageSize;
  final double? width;
  final double? height;
  final _LayoutType layoutType;

  _BkFlutterImageRenderObjectWidget({
    Key? key,
    required this.layoutType,
    required this.callBack,
    required this.fit,
    required this.imageSize,
    this.width,
    this.height,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    // TODO: implement createRenderObject
    return _BkFlutterImageRenderObject(layoutType: layoutType,imageSize: imageSize, width: width, height: height, fit: fit,callBack: callBack,);
  }

  @override
  void updateRenderObject(BuildContext context, _BkFlutterImageRenderObject renderObject) {
    // TODO: implement updateRenderObject
    renderObject
    ..layoutType = layoutType
    ..fit = fit
    ..imageSize = imageSize
    ..callBack = callBack
    ..width = width
    ..height = height;
  }
}

logger(dynamic msgs) {
  assert(() {
    debugPrint('[DEBUG] # $msgs');
    return true;
  }());
}
