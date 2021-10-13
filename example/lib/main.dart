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
  bool useFlutterImage = false;
  String imageUrl = 'https://images.pexels.com/photos/4678697/pexels-photo-4678697.jpeg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:Text('flutter 使用原生image view'),actions: <Widget>[
        IconButton(icon: Icon(Icons.list), onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (c) {
            return GridListDemo();
          }));
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
                        max: 400,
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
                        max: 400,
                        onChanged: (value) {
                          setState(() {
                            height = value.roundToDouble();
                          });
                        }),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text('是否使用原生层加载图片'),
                    Checkbox(
                      value: useFlutterImage,
                      onChanged: (value) {
                        setState(() {
                          useFlutterImage = value;
                        });
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
          Center(
            child: SafeArea(
              child: Container(
                width: width,
                height: height,
                child: useFlutterImage
                    ? BkFlutterImage(
                        url: imageUrl,
                        width: width,
                        height: height,
                        centerCrop: true,
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: width,
                        height: height,
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
