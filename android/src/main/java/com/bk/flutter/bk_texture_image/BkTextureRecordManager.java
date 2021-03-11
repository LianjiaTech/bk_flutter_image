package com.bk.flutter.bk_texture_image;

import java.util.HashMap;
import java.util.Map;

public class BkTextureRecordManager {

    private Map<String, BkTextureRecord> textureRecords = new HashMap<>();

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



    public BkTextureRecord findUnusedById(long textureId) {
        for (BkTextureRecord record : textureRecords.values()) {
            if (textureId == record.getTextureId()) {
                if (record.getRefCount().getAndDecrement() > 0) {
                    return null;
                }
                return record;
            }
        }
        return null;
    }

}
