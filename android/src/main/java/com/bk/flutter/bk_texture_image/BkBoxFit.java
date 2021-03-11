package com.bk.flutter.bk_texture_image;

// box_fit.dart
public enum BkBoxFit {
  fill,   /// 忽略原始图片比例，填充整个box
  contain, /// 尽可能大地将图片填充到box （保持图片比例）
  cover,   /// 居中裁剪
  fitWidth, /// 尽可能根据图片Width填充到box, Height按图片比例取最大值
  fitHeight,/// 尽可能根据图片Height填充到box, Width按图片比例最大值
  none,     /// 图片不进行裁剪、缩放，居中填充到box, 图片宽高超出部分被丢弃
  scaleDown; /// 图片完整显示（可能无法填充满），当图片需要裁剪是等价于contain, 不需要裁剪等价于none

  public static BkBoxFit valueOf(int ordinal) {
    if (ordinal < 0 || ordinal > values().length) {
      throw new IndexOutOfBoundsException("Invalid ordinal [ " + ordinal + " ], length is " + values().length);
    }
    return values()[ordinal];
  }
}

