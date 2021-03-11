package com.bk.flutter.bk_texture_image;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PaintFlagsDrawFilter;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.os.Handler;
import android.os.Looper;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.DataSource;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.bumptech.glide.load.engine.GlideException;
import com.bumptech.glide.load.engine.bitmap_recycle.BitmapPool;
import com.bumptech.glide.load.resource.bitmap.DownsampleStrategy;
import com.bumptech.glide.request.RequestListener;
import com.bumptech.glide.request.RequestOptions;
import com.bumptech.glide.request.target.Target;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.TextureRegistry;
import javax.microedition.khronos.opengles.GL10;

/**
 * BkFlutterImagePlugin
 */
public class BkFlutterImagePlugin implements FlutterPlugin, MethodCallHandler {


  private static final String CHANNEL_NAME = "bk_flutter_image";
  private static final String METHOD_CREATE = "create";
  private static final String METHOD_DISPOSE = "dispose";
  private static final String TAG = "BkFlutterImagePlugin";

  // surfaceTexture 宽高限制
  private static final int MAX_PIXELS = Math.min(GL10.GL_MAX_VIEWPORT_DIMS, GL10.GL_MAX_TEXTURE_SIZE);


  private Context mContext;
  private TextureRegistry mTextureRegistry;
  private float density;
  private int widthPixels;
  private int heightPixels;

  private BkTextureRecordManager mRecordManager;

  public BkFlutterImagePlugin() {
    mRecordManager = new BkTextureRecordManager();
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    final MethodChannel channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
    channel.setMethodCallHandler(this);
    mContext = flutterPluginBinding.getApplicationContext();
    /// 插件接口获取texture注册器
    mTextureRegistry = flutterPluginBinding.getTextureRegistry();

    density = mContext.getResources().getDisplayMetrics().density;
    widthPixels = mContext.getResources().getDisplayMetrics().widthPixels;
    heightPixels = mContext.getResources().getDisplayMetrics().heightPixels;
  }

  public static void registerWith(Registrar registrar) {
    throw new IllegalArgumentException("Error, please use v2 FlutterActivity!!");
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    try {
      if (METHOD_CREATE.equals(call.method)) {
        createTextureImage(call, result);
      } else if (METHOD_DISPOSE.equals(call.method)) {
        disposeTextureImage(call, result);
      } else {
        result.notImplemented();
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }


  private void createTextureImage(MethodCall call, Result result) {
    BkCallArgs args = new BkCallArgs(call);

    BkTextureRecord textureRecord = mRecordManager.find(args.uniqueKey());
    // TODO(): Bitmap失败是是否再做清除的textureRecord的逻辑
    if (textureRecord != null && textureRecord.getTextureEntry() != null) {
      textureRecord.getRefCount().getAndIncrement();
      safeReply(result, textureRecord.getTextureId());
    } else {
      BkTextureRecord record = new BkTextureRecord(args.uniqueKey(), mTextureRegistry.createSurfaceTexture());
      mRecordManager.add(record);
      args.setTextureId(record.getTextureId());
      loadTextureImage(args, result, record);
    }

  }

  private void disposeTextureImage(MethodCall call, Result result) {
    try {
      final int textureId = call.argument("textureId");
      BkTextureRecord record = mRecordManager.findUnusedById(textureId);
      if (record != null) {
        record.getTextureEntry().release();
        mRecordManager.remove(record);
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private void loadTextureImage(final BkCallArgs callArgs, final MethodChannel.Result result, final BkTextureRecord textureRecord) {

    final String url = callArgs.url;

    final BitmapPool pool = Glide.get(mContext).getBitmapPool();
    final boolean autoResize = callArgs.autoResize;

    RequestOptions options = new RequestOptions().diskCacheStrategy(DiskCacheStrategy.RESOURCE).downsample(DownsampleStrategy.AT_MOST);
    if (autoResize) {
      options = options.override(widthPixels, heightPixels);
    }

    Glide.with(mContext).asBitmap().load(url).listener(new RequestListener<Bitmap>() {
      @Override
      public boolean onLoadFailed(@Nullable GlideException e, Object model, Target<Bitmap> target, boolean isFirstResource) {
        BkLogger.d("glide onLoadFailed callArgs=" + callArgs.toString());
        safeReply(result, -1);
        return false;
      }

      @Override
      public boolean onResourceReady(Bitmap resource, Object model, Target<Bitmap> target, DataSource dataSource, boolean isFirstResource) {
        try {
          int targetWidth = Math.min(resource.getWidth(), MAX_PIXELS);
          int targetHeight = Math.min(resource.getHeight(), MAX_PIXELS);
          BkLogger.d("glide onResourceReady w:h = " + targetWidth + ":" + targetHeight);
          // 画布显示区域
          Rect canvasRect = new Rect(0, 0, targetWidth, targetHeight);

          SurfaceTexture surfaceTexture = textureRecord.getTextureEntry().surfaceTexture();
          surfaceTexture.setDefaultBufferSize(targetWidth, targetHeight);
          Surface surface = new Surface(surfaceTexture);
          Canvas canvas = surface.lockCanvas(canvasRect);

          // 图片显示区域
          Rect dstRect = BkBitmapUtils.getBitmapRect(resource, targetWidth, targetHeight, callArgs.imageFitMode);

          // 图片是否scale ？
          Bitmap scaleBitmap = BkBitmapUtils.tryScaleBitmap(pool, resource, targetWidth, targetHeight, callArgs.imageFitMode);
          canvas.setDrawFilter(new PaintFlagsDrawFilter(0, Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG));
          canvas.drawBitmap(scaleBitmap, null, dstRect, null);

          surface.unlockCanvasAndPost(canvas);
          surface.release();

          safeReply(result, callArgs.textureId);

        } catch (Exception e) {
          e.printStackTrace();
          BkLogger.e("glide onResourceReady Exception callArgs=" + callArgs.toString());
          //result.success(-1);
          //标志纹理失败
          textureRecord.getTextureValid().set(false);
        }

        return false;
      }
    }).apply(options).submit();


  }
  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    mContext = null;
    mTextureRegistry = null;
  }


  static String uniqueCall(MethodCall call) {
    return call.arguments.toString();
  }


  private void safeReply(final MethodChannel.Result result, final long textureId) {
    try {
      new Handler(Looper.getMainLooper()).post(new Runnable() {
        @Override
        public void run() {
          try {
            result.success(textureId);
          } catch (Exception e) {
            BkLogger.e("safeReply MainLooper Exception =" + e.getLocalizedMessage());
          }
        }
      });
    } catch (Exception e) {
      BkLogger.e("safeReply Exception =" + e.getLocalizedMessage());
    }
  }

}
