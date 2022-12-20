import 'package:flutter/material.dart';
import 'package:bk_flutter_image/bk_flutter_image.dart';

import 'exts.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
    );
  }

}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  double width = 300;
  double height = 300;
  BoxFit fit = BoxFit.cover;
  bool useFlutterImage = true;
  String imageUrl ='https://image2.ljcdn.com/utopia-file/p1/215a16c18b2c6ad44a61ff077f12b64fd937398c-3840-2560!m_fit,w_2560,o_auto,f_jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:Text('flutter 使用原生image view'),actions: <Widget>[
        IconButton(icon: Icon(Icons.list), onPressed: (){
          Navigator.push(context, DialogRoute(context: context, builder: (c) {
            return GridListDemo();
          }));
          // Navigator.push(context, MaterialPageRoute(builder: (c) {
          //   return GridListDemo();
          // }));
        })
      ],),
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
                Text('flutter这边的图片container参数设置'),
                Row(
                  children: <Widget>[
                    Text('flutter上的宽度'),
                    Slider(
                        value: width,
                        min: 100,
                        max: 500,
                        onChanged: (value) {
                          setState(() {
                            width = value.roundToDouble();
                          });
                        }),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text('flutter上的高度'),
                    Slider(
                        value: height,
                        min: 100,
                        max: 500,
                        onChanged: (value) {
                          setState(() {
                            height = value.roundToDouble();
                          });
                        }),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text('使用Texture加载图片: $useFlutterImage'),
                    Checkbox(
                      value: useFlutterImage,
                      onChanged: (value) {
                        setState(() {
                          useFlutterImage = value;
                        });
                      },
                    ),
                    Text('Cover:'),
                    Checkbox(
                      value: fit == BoxFit.cover,
                      onChanged: (value) {
                        setState(() {
                          fit = value ? BoxFit.cover : BoxFit.none;
                        });
                      },
                    ),
                    Text('Contain:'),
                    Checkbox(
                      value: fit == BoxFit.contain,
                      onChanged: (value) {
                        setState(() {
                          fit = value ? BoxFit.contain : BoxFit.none;
                        });
                      },
                    ),
                    Text('fill:'),
                    Checkbox(
                      value: fit == BoxFit.fill,
                      onChanged: (value) {
                        setState(() {
                          fit = value ? BoxFit.fill : BoxFit.none;
                        });
                      },
                    ),
                    Text('fitWidth:'),
                    Checkbox(
                      value: fit == BoxFit.fitWidth,
                      onChanged: (value) {
                        setState(() {
                          fit = value ? BoxFit.fitWidth : BoxFit.none;
                        });
                      },
                    ),
                    Text('fitHeight:'),
                    Checkbox(
                      value: fit == BoxFit.fitHeight,
                      onChanged: (value) {
                        setState(() {
                          fit = value ? BoxFit.fitHeight : BoxFit.none;
                        });
                      },
                    ),
                    Text('scale:'),
                    Checkbox(
                      value: fit == BoxFit.scaleDown,
                      onChanged: (value) {
                        setState(() {
                          fit = value ? BoxFit.scaleDown : BoxFit.none;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Center(
            child: SafeArea(
              child:Column(
                children:[
                  Container(// width: 400,
                  // height: 100,
                  child: useFlutterImage
                      ? BkFlutterImage(
                    url: imageUrl,
                    height: height,
                    width: width,
                    fit: fit,
                  )
                      : Image.network(
                    imageUrl,
                    fit: fit,
                    width: width,
                    height: height,
                  ),

                ), ]),

            ),
          )
        ],
      ),
    );
  }
}
