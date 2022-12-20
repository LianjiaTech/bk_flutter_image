// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:bk_flutter_image/bk_flutter_image.dart';

enum GridDemoTileStyle {
  deleteMode,
  selectMode
}

typedef BannerTapCallback = void Function(Photo photo);

const double _kMinFlingVelocity = 800.0;
const String _kGalleryAssetsPackage = 'flutter_gallery_assets';

class Photo {
  Photo({
    this.url,
    this.assetPackage,
    this.title,
    this.caption,
    this.isFavorite = false,
    this.mode=BoxFit.fill,
  });

  final String url;
  final String assetPackage;
  final String title;
  final String caption;
  final BoxFit mode;

  bool isFavorite;
  String get tag => url; // Assuming that all asset names are unique.

  bool get isValid => url != null && title != null && caption != null && isFavorite != null;
}

class GridPhotoViewer extends StatefulWidget {
  const GridPhotoViewer({ Key key, this.photo }) : super(key: key);

  final Photo photo;

  @override
  _GridPhotoViewerState createState() => _GridPhotoViewerState();
}

class _GridTitleText extends StatelessWidget {
  const _GridTitleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }
}

class _GridPhotoViewerState extends State<GridPhotoViewer> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Offset> _flingAnimation;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _normalizedOffset;
  double _previousScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The maximum offset value is 0,0. If the size of this renderer's box is w,h
  // then the minimum offset value is w - _scale * w, h - _scale * h.
  Offset _clampOffset(Offset offset) {
    final Size size = context.size;
    final Offset minOffset = Offset(size.width, size.height) * (1.0 - _scale);
    return Offset(offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  void _handleFlingAnimation() {
    setState(() {
      _offset = _flingAnimation.value;
    });
  }

  void _handleOnScaleStart(ScaleStartDetails details) {
    setState(() {
      _previousScale = _scale;
      _normalizedOffset = (details.focalPoint - _offset) / _scale;
      // The fling animation stops if an input gesture starts.
      _controller.stop();
    });
  }

  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale).clamp(1.0, 4.0);
      // Ensure that image location under the focal point stays in the same place despite scaling.
      _offset = _clampOffset(details.focalPoint - _normalizedOffset * _scale);
    });
  }

  void _handleOnScaleEnd(ScaleEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity)
      return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    final double distance = (Offset.zero & context.size).shortestSide;
    _flingAnimation = _controller.drive(Tween<Offset>(
      begin: _offset,
      end: _clampOffset(_offset + direction * distance),
    ));
    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _handleOnScaleStart,
      onScaleUpdate: _handleOnScaleUpdate,
      onScaleEnd: _handleOnScaleEnd,
      child: ClipRect(
        child: Transform(
          transform: Matrix4.identity()
            ..translate(_offset.dx, _offset.dy)
            ..scale(_scale),
          child:
              // Image.network(widget.photo.url,),
          BkFlutterImage(
            url: widget.photo.url,
            width: 150,
            height: 150,
            //package: widget.photo.assetPackage,
            fit: BoxFit.contain,
            autoResize: false,
          ),
        ),
      ),
    );
  }
}

class GridDemoPhotoItem extends StatelessWidget {
  GridDemoPhotoItem({
    Key key,
    @required this.photo,
    @required this.tileStyle,
    @required this.onBannerTap,
  }) : assert(photo != null && photo.isValid),
        assert(tileStyle != null),
        assert(onBannerTap != null),
        super(key: key);

  final Photo photo;
  final GridDemoTileStyle tileStyle;
  final BannerTapCallback onBannerTap; // User taps on the photo's header or footer.

  void showPhoto(BuildContext context) {
   Navigator.push(context, MaterialPageRoute<void>(
     builder: (BuildContext context) {
       return Scaffold(
         appBar: AppBar(
           title: Text(photo.title),
         ),
         body: SizedBox.expand(
           child: Hero(
             tag: photo.tag,
             child: GridPhotoViewer(photo: photo),
           ),
         ),
       );
     }
   ));
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = GestureDetector(
      onTap: () { showPhoto(context); },
      child: BkFlutterImage(
        url: photo.url,
        fit: photo.mode,
        placeholder: 'images/01.jpg',
        autoResize: true,
        imageErrorBuilder: (BuildContext context,Object error,StackTrace stacktrace){
          return Text(error);
        },
      ),
    );

    final IconData icon = photo.isFavorite ? Icons.star : Icons.star_border;

    switch (tileStyle) {
      case GridDemoTileStyle.deleteMode:
        return GridTile(
          header: GestureDetector(
            onTap: () { onBannerTap(photo); },
            child: GridTileBar(
              title: _GridTitleText(photo.title),
              backgroundColor: Colors.black45,
              leading: Icon(
                Icons.delete_forever,
                color: Colors.white,
              ),
            ),
          ),
          child: image,
        );

      case GridDemoTileStyle.selectMode:
        return GridTile(
          footer: GestureDetector(
            onTap: () { onBannerTap(photo); },
            child: GridTileBar(
              backgroundColor: Colors.black45,
              title: _GridTitleText(photo.title),
              subtitle: _GridTitleText(photo.caption),
              trailing: Icon(
                icon,
                color: Colors.white,
              ),
            ),
          ),
          child: image,
        );
    }
    assert(tileStyle != null);
    return null;
  }

}

class GridListDemo extends StatefulWidget {
  const GridListDemo({ Key key }) : super(key: key);

  @override
  GridListDemoState createState() => GridListDemoState();

}

class GridListDemoState extends State<GridListDemo> {
  GridDemoTileStyle _tileStyle = GridDemoTileStyle.selectMode;

  @override
  void dispose() {
    super.dispose();
  }

 @override
 @override
 void initState() {
   super.initState();
    for(int i = 0; i < 10; i ++) {
      photos.addAll(allModephotos(i));
    }
 }

  List<Photo> allModephotos(int i){
    List<Photo> temp =   <Photo>[
      Photo(
      url: photosUrls[i],
      assetPackage: _kGalleryAssetsPackage,
      title: 'BoxFit.fill',
      caption: 'Fisherman',mode: BoxFit.fill,
    ),
      Photo(
        url: photosUrls[i],
        assetPackage: _kGalleryAssetsPackage,
        title: 'BoxFit.cover',
        caption: 'Fisherman',mode: BoxFit.cover,
      ),
      Photo(
        url: photosUrls[i],
        assetPackage: _kGalleryAssetsPackage,
        title: 'BoxFit.contain',
        caption: 'Fisherman',mode: BoxFit.contain,
      ),
      Photo(
        url: photosUrls[i],
        assetPackage: _kGalleryAssetsPackage,
        title: 'BoxFit.fitWidth',
        caption: 'Fisherman',mode: BoxFit.fitWidth,
      ),
      Photo(
        url: photosUrls[i],
        assetPackage: _kGalleryAssetsPackage,
        title: 'BoxFit.fitHeight',
        caption: 'Fisherman',
        mode: BoxFit.fitHeight,
      ),
      Photo(
        url: photosUrls[i],
        assetPackage: _kGalleryAssetsPackage,
        title: 'BoxFit.scaleDown',
        caption: 'Fisherman',
        mode: BoxFit.scaleDown,
      ),
    ];
    return temp;
  }

  List<Photo> photos = <Photo>[
  ];

  void changeTileStyle(GridDemoTileStyle value) {
    setState(() {
      _tileStyle = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grid list'),
        actions: <Widget>[
          //MaterialDemoDocumentationButton(GridListDemo.routeName),
          PopupMenuButton<GridDemoTileStyle>(
            onSelected: changeTileStyle,
            itemBuilder: (BuildContext context) => <PopupMenuItem<GridDemoTileStyle>>[
              const PopupMenuItem<GridDemoTileStyle>(
                value: GridDemoTileStyle.deleteMode,
                child: Text('Delete Mode'),
              ),
              const PopupMenuItem<GridDemoTileStyle>(
                value: GridDemoTileStyle.selectMode,
                child: Text('Select Mode'),
              ),
            ],
          ),
        ],
      ),
      body:
      Column( children: <Widget>[
         Expanded( child: SafeArea(
                        top: false,
                        bottom: false,
                        child: GridView.count(
                      crossAxisCount:  (orientation == Orientation.portrait) ? 2 : 3,
                        mainAxisSpacing: 4.0,
                        crossAxisSpacing: 4.0,
                        padding: const EdgeInsets.all(4.0),
                    childAspectRatio: (orientation == Orientation.portrait) ? 1.0 : 1.3,
                    children: photos.map<Widget>((Photo photo) {
                      return GridDemoPhotoItem(
                        photo: photo,
                        tileStyle: _tileStyle,
                        onBannerTap: (Photo photo) {
                          setState(() {
                            if (GridDemoTileStyle.deleteMode == _tileStyle) {
                              photos.remove(photo);
                            } else {
                              photo.isFavorite = !photo.isFavorite;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
    ),
    );
  }
}

List<String> photosUrls = <String>[
  'https://images.pexels.com/photos/6383210/pexels-photo-6383210.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://images.pexels.com/photos/1751279/pexels-photo-1751279.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://images.pexels.com/photos/2434269/pexels-photo-2434269.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://images.pexels.com/photos/7307618/pexels-photo-7307618.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://images.pexels.com/photos/3932944/pexels-photo-3932944.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://images.pexels.com/photos/4578770/pexels-photo-4578770.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://images.pexels.com/photos/9060607/pexels-photo-9060607.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://images.pexels.com/photos/1915715/pexels-photo-1915715.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://images.pexels.com/photos/4683675/pexels-photo-4683675.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://images.pexels.com/photos/9166412/pexels-photo-9166412.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://images.pexels.com/photos/2681319/pexels-photo-2681319.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://images.pexels.com/photos/6243804/pexels-photo-6243804.jpeg?auto=compress&cs=tinysrgb&dpr=2&w=500',
  'https://image2.ljcdn.com/utopia-file/p1/215a16c18b2c6ad44a61ff077f12b64fd937398c-3840-2560!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/215a16c18b2c6ad44a61ff077f12b64fd937398c-3840-2560!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/d7884f6c4cf7e43e826018a8576e6bf53d07fe40-5424-3632!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/e279f611cea722a7225ef581bace829d68dd3463-5328-4000!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/8834c7631bfddee25391079b6951e1d6c10c40b8-2560-1920!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/90aacb7b156c0670dd8fe203a6cf372d5b4bc1ca-5376-3314!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/d57bad88338fcdba2405a02dda5415b73e7cbb4c-6480-4320!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/b7e71ed8ec092e6b25ca4315d43b11aee85a76b7-2560-1707!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/a2909d3b7d35165daf0cea9697df470e3e61d747-5973-4480!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/d5202b01af7a978a9f4332208780265bf1ac3617-5760-3840!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/51392b46baa507e7b97ad9fadbdb0bf6bcf0bc06-2667-2000!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/861520ecf875fc750de9565fb01548e7e94fa95a-5994-3996!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/3e1ebe4a9bb66b1322bd90e5b185b8e0d9661dc1-5472-3648!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/5e1d544c33118451ebaca9aae349a9c704e5cb2c-8448-6336!m_fit,w_2560,o_auto,f_jpg',
  'https://image2.ljcdn.com/utopia-file/p1/e7eeeb5b4a079a0e4f51c7c955da85464f2e93a5-2400-1800!m_fit,w_2560,o_auto,f_jpg',
  "https://image2.ljcdn.com/utopia-file/p1/215a16c18b2c6ad44a61ff077f12b64fd937398c-3840-2560!m_fit,w_2560,o_auto,f_jpg",
  "https://image2.ljcdn.com/utopia-file/p1/d7884f6c4cf7e43e826018a8576e6bf53d07fe40-5424-3632!m_fit,w_2560,o_auto,f_jpg",
  "https://image2.ljcdn.com/utopia-file/p1/e279f611cea722a7225ef581bace829d68dd3463-5328-4000!m_fit,w_2560,o_auto,f_jpg",
  "https://image2.ljcdn.com/utopia-file/p1/90aacb7b156c0670dd8fe203a6cf372d5b4bc1ca-5376-3314!m_fit,w_2560,o_auto,f_jpg",
];