package com.bk.flutter.bk_texture_image;

import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.view.TextureRegistry;

public class BkTextureRecord {
    // 同一个纹理多次使用计数，当最后一个dispose时才移除
    private AtomicInteger refCount = new AtomicInteger(0);
    // 纹理是否有效
    private AtomicBoolean textureValid = new AtomicBoolean(true);

    private TextureRegistry.SurfaceTextureEntry textureEntry;

    private String key;

    public BkTextureRecord(String key, TextureRegistry.SurfaceTextureEntry textureEntry) {
        this.textureEntry = textureEntry;
        this.key = key;
    }

    public AtomicInteger getRefCount() {
        return refCount;
    }

    public AtomicBoolean getTextureValid() {
        return textureValid;
    }

    public TextureRegistry.SurfaceTextureEntry getTextureEntry() {
        return textureEntry;
    }

    public void setTextureEntry(TextureRegistry.SurfaceTextureEntry textureEntry) {
        this.textureEntry = textureEntry;
    }

    public String getKey() {
        return key;
    }

    public long getTextureId() {
        return textureEntry.id();
    }
}
