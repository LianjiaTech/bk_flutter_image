package com.bk.flutter.bk_texture_image;

import java.util.concurrent.ConcurrentHashMap;


public class BkTextureRecordManager {

  private static final int DEF_CACHE_SIZE = 268435456; // 256MB
  private static final int MAX_CACHE_SIZE = 1073741824; // 1024MB
  private final ConcurrentHashMap<BkCallArgs, BkTextureRecord> textureRecords = new ConcurrentHashMap<>();
  private final BkLruCache textureCacheRecords = new BkLruCache(DEF_CACHE_SIZE);

  BkTextureRecordManager() {}

  public void add(BkTextureRecord record) {
    textureRecords.put(record.getCall(), record);
  }

  public BkTextureRecord remove(BkTextureRecord record) {
    return textureRecords.remove(record.getCall());
  }

  public BkTextureRecord findReusableByCall(BkCallArgs key) {
    for (BkCallArgs bkCallArgs : textureRecords.keySet()) {
      if (bkCallArgs.hasReusableTexture(key)) {
        return textureRecords.get(bkCallArgs);
      }
    }
    for (BkCallArgs bkCallArgs : textureCacheRecords.snapshot().keySet()) {
      // 如果找到可复用的纹理直接返回
      if (bkCallArgs.hasReusableTexture(key)) {
        return textureCacheRecords.get(bkCallArgs);
      }
    }
    return null;
  }

  /**
   * 通过纹理 id 找到
   * @param textureId
   * @return
   */
  public BkCallArgs findCallById(long textureId) {
    for (BkCallArgs bkCallArgs : textureRecords.keySet()) {
      if (textureId == bkCallArgs.getTextureId()) {
        return bkCallArgs;
      }
    }
    for (BkCallArgs bkCallArgs : textureCacheRecords.snapshot().keySet()) {
      if (textureId == bkCallArgs.getTextureId()) {
        return bkCallArgs;
      }
    }
    return null;
  }

  /**
   *
   * @param textureId: 待释放纹理 id
   * @return BkTextureRecord: 从缓存中清理的记录
   */
  public BkTextureRecord maybeCacheAndReleaseOldest(long textureId) {
    BkCallArgs bkCallArgs = findCallById(textureId);
    if (bkCallArgs == null) {
      return null;
    }
    BkTextureRecord bkTextureRecord = textureRecords.get(bkCallArgs);
    textureRecords.remove(bkCallArgs);
    if (bkTextureRecord != null) {
      return textureCacheRecords.put(bkCallArgs, bkTextureRecord);
    }
    return null;
  }

  public void clean() {
    textureRecords.clear();
  }

  /**
   * diskCacheMaxSize 磁盘缓存Android暂不关注.
   * memoryCacheMaxSize 设置 LruCache MaxSize, 当纹理需要释放时我们优先将其缓存起来
   */
  public void setCacheMaxSize(double diskCacheMaxSize, double memoryCacheMaxSize) {
    if (memoryCacheMaxSize > MAX_CACHE_SIZE) {
      BkLogger.w(String.format("memoryCacheMaxSize > %s, set to MAX_CACHE_SIZE: %s", MAX_CACHE_SIZE, MAX_CACHE_SIZE));
      this.textureCacheRecords.resize(MAX_CACHE_SIZE);
    } else {
      this.textureCacheRecords.resize((int) memoryCacheMaxSize);
    }
  }
}
