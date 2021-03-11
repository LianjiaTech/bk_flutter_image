package com.bk.flutter.bk_texture_image;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Rect;
import io.flutter.Log;

import androidx.annotation.NonNull;

import com.bumptech.glide.load.engine.bitmap_recycle.BitmapPool;
import com.bumptech.glide.load.resource.bitmap.TransformationUtils;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class BkBitmapUtils {

  private static final String TAG = "BitmapUtils";

  // 返回宽高
  public static int[] fitCenter(@NonNull Bitmap inBitmap, int width, int height) {
    int[] result = new int [] {width, height};
    if (inBitmap.getWidth() == width && inBitmap.getHeight() == height) {
      Log.v(TAG, "requested target size matches input, returning input");
      return result;
    }
    final float widthPercentage = width / (float) inBitmap.getWidth();
    final float heightPercentage = height / (float) inBitmap.getHeight();
    final float minPercentage = Math.min(widthPercentage, heightPercentage);

    int targetWidth = Math.round(minPercentage * inBitmap.getWidth());
    int targetHeight = Math.round(minPercentage * inBitmap.getHeight());

    if (inBitmap.getWidth() == targetWidth && inBitmap.getHeight() == targetHeight) {
      Log.v(TAG, "adjusted target size matches input, returning input");
    } else {
      targetWidth = (int) (minPercentage * inBitmap.getWidth());
      targetHeight = (int) (minPercentage * inBitmap.getHeight());
    }

    result[0] = targetWidth;
    result[1] = targetHeight;
    return result;

  }


  public static int[] centerInside(@NonNull Bitmap inBitmap, int width, int height) {
    int[] result = new int [] {width, height};
    if (inBitmap.getWidth() <= width && inBitmap.getHeight() <= height) {
      Log.v(TAG, "requested target size larger or equal to input, returning input");
      result[0] = inBitmap.getWidth();
      result[1] = inBitmap.getHeight();
      return result;
    } else {
      Log.v(TAG, "requested target size too big for input, fit centering instead");
      return fitCenter(inBitmap, width, height);
    }
  }

  public static int[] fitWidth(@NonNull Bitmap inBitmap, int width, int height) {
    int[] result = new int [] {width, height};
    final float widthPercentage = width / (float) inBitmap.getWidth();
    if (inBitmap.getWidth() <= width) {
      Log.v(TAG, "requested target size larger or equal to input, returning input");

      result[0] = width;
      result[1] = (int) (inBitmap.getHeight() * widthPercentage);
      return result;
    } else {
      Log.v(TAG, "requested target size too big for input, fit centering instead");
      result[0] = width;
      result[1] = (int) (inBitmap.getHeight() * widthPercentage);
      return result;
    }
  }

  public static int[] fitHeight(@NonNull Bitmap inBitmap, int width, int height) {
    int[] result = new int [] {width, height};
    final float heightPercentage = height / (float) inBitmap.getHeight();
    if (inBitmap.getWidth() <= width) {
      Log.v(TAG, "requested target size larger or equal to input, returning input");
      result[0] = (int) (inBitmap.getWidth() * heightPercentage);
      result[1] = height;
      return result;
    } else {
      Log.v(TAG, "requested target size too big for input, fit centering instead");
      result[0] = (int) (inBitmap.getWidth() * heightPercentage);
      result[1] = height;
      return result;
    }
  }

  public static int[] fitNone(@NonNull Bitmap inBitmap, int width, int height) {

    final float widthPercentage = width / (float) inBitmap.getWidth();
    final float heightPercentage = height / (float) inBitmap.getHeight();

    if (widthPercentage >= heightPercentage) {
      return fitHeight(inBitmap, width, height);
    } else {
      return fitWidth(inBitmap, width, height);
    }

  }

  public static int[] scaleDown(@NonNull Bitmap inBitmap, int width, int height) {

    final float widthPercentage = width / (float) inBitmap.getWidth();
    final float heightPercentage = height / (float) inBitmap.getHeight();
    final float minPercentage = Math.min(widthPercentage, heightPercentage);
    int w = (int) (minPercentage * inBitmap.getWidth());
    int h = (int) (minPercentage * inBitmap.getHeight());
    return new int[] {w, h};
  }

  public static int[] contain(@NonNull Bitmap inBitmap, int width, int height) {

    final float widthPercentage = width / (float) inBitmap.getWidth();
    final float heightPercentage = height / (float) inBitmap.getHeight();
    final float minPercentage = Math.min(widthPercentage, heightPercentage);
    int w = (int) (minPercentage * inBitmap.getWidth());
    int h = (int) (minPercentage * inBitmap.getHeight());
    return new int[] {w, h};
  }

  // 需要居中裁剪
  public static int[] cover(@NonNull Bitmap inBitmap, int width, int height) {
    return new int[] {width, height};
  }

  public static Bitmap coverCropBitmap(@NonNull Bitmap inBitmap, int width, int height) {

    Bitmap scaleOutBitmap = scaleBitmap(inBitmap, width, height);

    int scaleOutBitmapWidth = scaleOutBitmap.getWidth();
    int scaleOutBitmapHeight = scaleOutBitmap.getHeight();
    int x, y, cropWidth, cropHeight;
    if (width > height) {
      x = 0;
      y = (scaleOutBitmapHeight - height) / 2;
    } else {
      x = (scaleOutBitmapWidth - width) / 2;
      y = 0;
    }

    return Bitmap.createBitmap(scaleOutBitmap, x, y, width, height, null, false);
  }

  public static Bitmap fitWidthCropBitmap(@NonNull Bitmap inBitmap, int width, int height) {

    Bitmap scaleOutBitmap = scaleBitmap(inBitmap, width, height);

    int scaleOutBitmapWidth = scaleOutBitmap.getWidth();
    int scaleOutBitmapHeight = scaleOutBitmap.getHeight();
    int x, y, cropWidth, cropHeight;
    if (width > height) {
      x = 0;
      y = (scaleOutBitmapHeight - height) / 2;
    } else {
      x = (scaleOutBitmapWidth - width) / 2;
      y = 0;
    }

    return Bitmap.createBitmap(scaleOutBitmap, x, y, width, height, null, false);
  }


  private static Bitmap scaleBitmap(@NonNull Bitmap inBitmap, int newWidth, int newHeight) {
    int width = inBitmap.getWidth();
    int height = inBitmap.getHeight();
    float scaleWidth = ((float) newWidth) / width;
    float scaleHeight = ((float) newHeight) / height;
    Matrix matrix = new Matrix();
    matrix.postScale(scaleWidth, scaleHeight);// 使用后乘
    return Bitmap.createBitmap(inBitmap, 0, 0, newWidth, newHeight, matrix, false);
  }

  private static Matrix applyMatrix(int width, int height, int newWidth, int newHeight) {
    float scaleWidth = ((float) newWidth) / width;
    float scaleHeight = ((float) newHeight) / height;
    Matrix matrix = new Matrix();
    matrix.postScale(scaleWidth, scaleHeight);
    return matrix;
  }

  private static void applyMatrix(
      @NonNull Bitmap inBitmap, @NonNull Bitmap targetBitmap, Matrix matrix) {
    BITMAP_DRAWABLE_LOCK.lock();
    try {
      Canvas canvas = new Canvas(targetBitmap);
      canvas.drawBitmap(inBitmap, matrix, DEFAULT_PAINT);
      clear(canvas);
    } finally {
      BITMAP_DRAWABLE_LOCK.unlock();
    }
  }

  // Avoids warnings in M+.
  private static void clear(Canvas canvas) {
    canvas.setBitmap(null);
  }

  private static final Lock BITMAP_DRAWABLE_LOCK = new ReentrantLock();
  public static final int PAINT_FLAGS = Paint.DITHER_FLAG | Paint.FILTER_BITMAP_FLAG;
  private static final Paint DEFAULT_PAINT = new Paint(PAINT_FLAGS);

  /// example.
  /// srcRect 240 * 360
  /// cropRect 240 * 150
  static Rect getBitmapRect(Bitmap inBitmap, int boxWidth, int boxHeight, int boxFitIndex) {
    final int imgWidth = inBitmap.getWidth();
    final int imgHeight = inBitmap.getHeight();
    int targetW, targetH;
    Rect cropRect = new Rect(0, 0, imgWidth, imgHeight);
    BkBoxFit boxFit = BkBoxFit.valueOf(boxFitIndex);
    switch (boxFit) {
      // fill:填充到容器中,拉伸填充
      case fill: {
        Log.d(TAG, "getBitmapRect: ");
        cropRect.left = 0;
        cropRect.right = boxWidth;
        cropRect.top = 0;
        cropRect.bottom = boxHeight;
        break;
      }
      // contain：图片不会超出容器边界
      case contain: {
        int[] wh = BkBitmapUtils.contain(inBitmap, boxWidth, boxHeight);
        cropRect.left = (boxWidth - wh[0]) / 2;
        cropRect.right = boxWidth - cropRect.left;
        cropRect.top = (boxHeight - wh[1]) / 2;
        cropRect.bottom = boxHeight - cropRect.top;
        break;
      }
      // cover：充满容器，可能会被截断
      case cover: {
        int[] wh = BkBitmapUtils.cover(inBitmap, boxWidth, boxHeight);
        cropRect.left = (boxWidth - wh[0]) / 2;
        cropRect.right = boxWidth - cropRect.left;
        cropRect.top = (boxHeight - wh[1]) / 2;
        cropRect.bottom = boxHeight - cropRect.top;
        break;
      }
      // fitWidth：宽度填充
      case fitWidth: {
        int[] wh = BkBitmapUtils.fitWidth(inBitmap, boxWidth, boxHeight);
        cropRect.left = 0;
        cropRect.right = boxWidth;
        if (boxHeight >= wh[1]) {
          cropRect.top = (boxHeight - wh[1]) / 2;
          cropRect.bottom = boxHeight - cropRect.top;
        } else {
          cropRect.top = 0;
          cropRect.bottom = boxHeight;
        }

        break;
      }
      // fitHeight:高度填充
      case fitHeight: {
        int[] wh = BkBitmapUtils.fitHeight(inBitmap, boxWidth, boxHeight);
        cropRect.top = 0;
        cropRect.bottom = boxHeight;
        if (boxWidth >= wh[0]) {
          cropRect.left = (boxWidth - wh[0]) / 2;
          cropRect.right = boxWidth - cropRect.left;
        } else {
          cropRect.left = 0;
          cropRect.right = boxWidth;
        }

        break;
      }
      // scaleDown：居中显示，如果图片太大，缩小到在容器内展示，不超出容器边界
      case scaleDown: {
        int[] wh = BkBitmapUtils.scaleDown(inBitmap, boxWidth, boxHeight);
        cropRect.left = (boxWidth - wh[0]) / 2;
        cropRect.right = boxWidth - cropRect.left;
        cropRect.top = (boxHeight - wh[1]) / 2;
        cropRect.bottom = boxHeight - cropRect.top;
        break;
      }
      // none：不修改图片大小，在容器中居中展示,超出部分不用管
      case none: {
        int[] wh = BkBitmapUtils.fitNone(inBitmap, boxWidth, boxHeight);
        cropRect.left = (boxWidth - wh[0]) / 2;
        cropRect.right = boxWidth - cropRect.left;
        cropRect.top = (boxHeight - wh[1]) / 2;
        cropRect.bottom = boxHeight - cropRect.top;
        break;
      }
      default:
        break;
    }

    return cropRect;
  }

  static Bitmap tryScaleBitmap(BitmapPool pool, Bitmap resource, int width, int height, int boxFitIndex) {
    BkBoxFit boxFit = BkBoxFit.valueOf(boxFitIndex);
    if (boxFit == BkBoxFit.fitWidth || boxFit == BkBoxFit.fitHeight || boxFit == BkBoxFit.cover) {
      return TransformationUtils.centerCrop(pool, resource, width, height);
    }
    return resource;
  }
}
