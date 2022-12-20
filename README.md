# bk_flutter_image——Flutter图片内存优化库

 ## 背景
 随着移动端业务中更多Flutter应用, 多图、大图复杂页面使用Flutter的Image.network(..) , FadeInImage.network(..)易出现出现OOM问题
 * [实践](https://mp.weixin.qq.com/s/yUm4UFggYLgDbj4_JCjEdg)

 ## 指南

 ### Android依赖 Glide 4.11.0

 ```gradle
 dependencies {
     implementation 'com.github.bumptech.glide:glide:4.11.0'
 }
 ```

 ### iOS 依赖 SDWebImage 5.12.6及以上 https://github.com/SDWebImage/SDWebImage/issues/3351
 pod 'SDWebImage','5.12.6' 

 ### 使用方式

 ```
 BkFlutterImage(
   url: imageUrl,
   width: width,
   height: height,
   autoResize: true,
   ...
 )
 ```

 ## License

 详情参见 [LICENSE](./LICENSE)。

 ## 版本历史
 具体版本历史请参看 [CHANGELOG.md](./CHANGELOG.md)。
