package com.bk.flutter.bk_texture_image;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class BkTextureRecordManager {

  private ConcurrentHashMap<String, BkTextureRecord> textureRecords = new ConcurrentHashMap<>();

  BkTextureRecordManager() {

  }

  public void add(BkTextureRecord record) {
    textureRecords.put(record.getKey(), record);
  }

  public BkTextureRecord remove(BkTextureRecord record) {
    return textureRecords.remove(record.getKey());
  }

  public BkTextureRecord find(String key) {
    return textureRecords.get(key);
  }


  // 返回待销毁的TextureRecord， 如果当前TextureRecord被使用数 > 1, 则不销毁返回null
  public BkTextureRecord findUnusedById(long textureId) {
    for (BkTextureRecord record : textureRecords.values()) {
      if (textureId == record.getTextureId()) {
        if (record.getRefCount().getAndDecrement() >= 1) {
          return null;
        }
        BkLogger.d("findUnusedById : -->" + record);
        return record;
      }
    }
    return null;
  }

  public void clean() {
    for (BkTextureRecord record : textureRecords.values()) {
      record.tryRelease();
    }
    textureRecords.clear();
  }
}
