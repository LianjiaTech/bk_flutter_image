package com.bk.flutter.bk_texture_image;


import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.view.TextureRegistry;

public class BkTextureRecord {
  // 同一个纹理多次使用计数，当最后一个dispose时才移除
  private AtomicInteger refCount = new AtomicInteger(1);
  // 纹理是否有效
  private final AtomicBoolean textureValid = new AtomicBoolean(true);

  private TextureRegistry.SurfaceTextureEntry textureEntry;

  private BkCallArgs call;
  private long textureId = 0L;
  private double textureWidth = 0L;
  private double textureHeight = 0L;
  private boolean isFullPixel = false;
  private String mError;

  public BkTextureRecord(BkCallArgs call, TextureRegistry.SurfaceTextureEntry textureEntry) {
    this.textureEntry = textureEntry;
    this.call = call;
  }

  public int refIncrementAndGet() {
    return refCount.incrementAndGet();
  }

  public int refDecrementAndGet() {
    return refCount.decrementAndGet();
  }

  public AtomicBoolean getTextureValid() {
    return textureValid;
  }

  public void setTextureValid(boolean valid) {
    this.textureValid.set(valid);
  }

  public boolean isValid() {
    return textureEntry != null && textureValid.get();
  }

  public TextureRegistry.SurfaceTextureEntry getTextureEntry() {
    textureId = textureEntry.id();
    return textureEntry;
  }

  public void setTextureEntry(TextureRegistry.SurfaceTextureEntry textureEntry) {
    this.textureEntry = textureEntry;
  }

  public BkCallArgs getCall() {
    return call;
  }

  public long getTextureId() {
    return textureId;
  }

  public void tryRelease() {
    if (textureEntry != null && textureEntry.surfaceTexture() != null) {
      if (VERSION.SDK_INT >= VERSION_CODES.O) {
        if (!textureEntry.surfaceTexture().isReleased()) {
          textureEntry.release();
        }
      } else {
        textureEntry.release();
      }
    }
  }

  public void setTextureWH(double w, double h) {
    textureWidth = w;
    textureHeight = h;
  }

  public double getTextureHeight() {
    return textureHeight;
  }

  public double getTextureWidth() {
    return textureWidth;
  }

  public void setFullPixel(boolean fullPixel) {
    isFullPixel = fullPixel;
  }

  public void setError(String error) {
    this.mError = error;
  }

  /**
   * 纹理占用内容（MB）
   */
  public int sizeOfMegaBytes() {
    return (int) (textureWidth * textureHeight * 4) >> 20;
  }

  public String response() {
    JSONObject jsonObject = new JSONObject();
    try {
      jsonObject.put("textureId", isValid() ? textureId : -1);
      jsonObject.put("textureWidth", textureWidth);
      jsonObject.put("textureHeight", textureHeight);
      jsonObject.put("isFullPixel", isFullPixel);
      jsonObject.put("error", mError);
    } catch (JSONException e) {
      e.printStackTrace();
    }
    return jsonObject.toString();
  }

  @Override
  public String toString() {
    return "TextureRecord{" +
        "refCount=" + refCount.get() +
        ", textureValid=" + textureValid.get() +
        ", textureId=" + textureEntry.id() +
        ", callArgs='" + call + '\'' +
        '}';
  }
}
