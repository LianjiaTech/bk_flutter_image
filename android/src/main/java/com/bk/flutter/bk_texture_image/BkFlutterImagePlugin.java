package com.bk.flutter.bk_texture_image;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PaintFlagsDrawFilter;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.os.Debug;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bumptech.glide.Glide;
import com.bumptech.glide.MemoryCategory;
import com.bumptech.glide.load.DataSource;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.bumptech.glide.load.engine.GlideException;
import com.bumptech.glide.load.engine.bitmap_recycle.BitmapPool;
import com.bumptech.glide.load.engine.cache.MemoryCache;
import com.bumptech.glide.load.resource.bitmap.BitmapEncoder;
import com.bumptech.glide.load.resource.bitmap.DownsampleStrategy;
import com.bumptech.glide.request.RequestListener;
import com.bumptech.glide.request.RequestOptions;
import com.bumptech.glide.request.target.Target;
import com.bumptech.glide.util.Executors;
import com.bumptech.glide.util.Util;

import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

import javax.microedition.khronos.opengles.GL10;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.TextureRegistry;

/**
 * BkFlutterTextureImageViewPlugin
 */
public class BkFlutterImagePlugin implements FlutterPlugin, MethodCallHandler,
    ActivityAware {

  private static final String CHANNEL_NAME = "bk_flutter_image";
  private static final String METHOD_CREATE = "create";
  private static final String METHOD_DISPOSE = "dispose";
  private static final String METHOD_CACHE = "setCacheSize";
  private static final String METHOD_UPDATE = "updateUrl";
  private static final String TAG = "BkFlutterImagePlugin";

  // surfaceTexture 宽高限制
  private static final int MAX_PIXELS = Math.min(GL10.GL_MAX_VIEWPORT_DIMS, GL10.GL_MAX_TEXTURE_SIZE);
  private static final int LIMIT_NATIVE_HEAP_SIZE = 157286400; //[经验值] 内存大于150MB的时候清理bitmap内存
  private Context mContext;
  //  private Activity mActivity;
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
      } else if (METHOD_CACHE.equals(call.method)) {
        setMaxCacheSize(call, result);
      }else {
        result.notImplemented();
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private void setMaxCacheSize(MethodCall call, Result result) {
    double memoryMaxSize = call.argument("memoryMaxSize");;
    double diskMaxSize = call.argument("diskMaxSize");
    mRecordManager.setCacheMaxSize(diskMaxSize, memoryMaxSize);
  }

  private void createTextureImage(MethodCall call, Result result) {
    BkCallArgs args = new BkCallArgs(call);

    BkTextureRecord textureRecord = mRecordManager.findReusableByCall(args);

    if (textureRecord != null && textureRecord.isValid()) {
      safeReply(result, textureRecord.response());
    } else {
      BkTextureRecord record = new BkTextureRecord(args, mTextureRegistry.createSurfaceTexture());
      mRecordManager.add(record);
      args.setTextureId(record.getTextureId());
      loadTextureImage(args, result, record);
    }

  }

  private void disposeTextureImage(MethodCall call, Result result) {
    try {
      final int textureId = call.argument("textureId");
      BkTextureRecord record = mRecordManager.maybeCacheAndReleaseOldest(textureId);
      if (record != null) {
        BkLogger.d("release texture memory : " + record);
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private void loadTextureImage(final BkCallArgs callArgs, final MethodChannel.Result result, final BkTextureRecord textureRecord) {

    final String url = callArgs.url;

    Glide.get(mContext).setMemoryCategory(MemoryCategory.LOW);
    final boolean autoResize = callArgs.autoResize;
    textureRecord.setFullPixel(!autoResize);
    RequestOptions options = new RequestOptions()
            .diskCacheStrategy(DiskCacheStrategy.ALL)
            .downsample(DownsampleStrategy.DEFAULT);
    if (autoResize) {
      options = options.override(Math.min(callArgs.width, MAX_PIXELS), Math.min(callArgs.height, MAX_PIXELS));
    }

    Glide.with(mContext).asBitmap().load(url).listener(new RequestListener<Bitmap>() {
      @Override
      public boolean onLoadFailed(@Nullable GlideException e, Object model, Target<Bitmap> target, boolean isFirstResource) {
        BkLogger.d("glide onLoadFailed callArgs=" + callArgs.toString());
        textureRecord.setTextureValid(false);
        textureRecord.setError(e != null ? e.getMessage() : "");
        safeReply(result, textureRecord.response());
        return true;
      }

      @Override
      public boolean onResourceReady(Bitmap resource, Object model, Target<Bitmap> target, DataSource dataSource, boolean isFirstResource) {
        try {
          int targetWidth = Math.min(resource.getWidth(), MAX_PIXELS);
          int targetHeight = Math.min(resource.getHeight(), MAX_PIXELS);
          textureRecord.setTextureWH(targetWidth, targetHeight);

          BkLogger.d("glide onResourceReady w:h = " + targetWidth + ":" + targetHeight + ", fr:" + isFirstResource + ", ds:" +dataSource);
          // 画布显示区域
          Rect canvasRect = new Rect(0, 0, targetWidth, targetHeight);
          SurfaceTexture surfaceTexture = textureRecord.getTextureEntry().surfaceTexture();
          Surface surface = new Surface(surfaceTexture);
          if (!surface.isValid()) {
            BkLogger.d("surface invalid");
            return false;
          }
          surfaceTexture.setDefaultBufferSize(targetWidth, targetHeight);
          Canvas canvas = surface.lockCanvas(canvasRect);

          // 图片显示区域
          Rect dstRect = new Rect(0, 0, targetWidth, targetHeight);

          // 图片是否scale ？
          canvas.setDrawFilter(new PaintFlagsDrawFilter(0, Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG));
          canvas.drawBitmap(resource, null, dstRect, null);

          surface.unlockCanvasAndPost(canvas);
          surface.release();

          safeReply(result, textureRecord.response());

        } catch (Exception e) {
          e.printStackTrace();
          BkLogger.d("glide onResourceReady Exception callArgs=" + callArgs.toString());
          //result.success(-1);
          //标志纹理失败
          textureRecord.setError(e.getMessage());
          textureRecord.setTextureValid(false);
          safeReply(result, textureRecord.response());
        } finally {
          long nativeHeapAllocatedSize = Debug.getNativeHeapAllocatedSize();
          if (nativeHeapAllocatedSize >= LIMIT_NATIVE_HEAP_SIZE) {
            BkLogger.d("NativeHeapAllocatedSize: " + (nativeHeapAllocatedSize >> 20) + "MB");
            clearGlideMemory();
          }
        }

        return false;
      }
    }).apply(options).preload();


  }
  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    mContext = null;
    mTextureRegistry = null;
    cleanResource();
  }

  private void safeReply(final MethodChannel.Result result, final String response) {
    Executors.mainThreadExecutor().execute(new Runnable() {
      @Override
      public void run() {
        try {
          result.success(response);
        } catch (Exception e) {
          BkLogger.d("safeReply MainLooper Exception =" + e.getLocalizedMessage());
        }
      }
    });
  }

  private void cleanResource() {
    mRecordManager.clean();
  }

  private void clearGlideMemory() {
    try {
      if (Util.isOnMainThread()) {
        Glide.get(mContext).clearMemory();
      }
    } catch (Exception e) {
      BkLogger.d("clearGlideMemory : " + e.getCause());
    }
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    clearGlideMemory();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {
    clearGlideMemory();
  }
}