package com.bk.flutter.bk_texture_image;

import android.util.LruCache;

public class BkLruCache extends LruCache<BkCallArgs, BkTextureRecord> {

    /**
     * @param maxSize for caches that do not override {@link #sizeOf}, this is
     *                the maximum number of entries in the cache. For all other caches,
     *                this is the maximum sum of the sizes of the entries in this cache.
     */
    public BkLruCache(int maxSize) {
        super(maxSize);
    }

    @Override
    protected void entryRemoved(boolean evicted, BkCallArgs key, BkTextureRecord oldValue, BkTextureRecord newValue) {
        super.entryRemoved(evicted, key, oldValue, newValue);
        oldValue.tryRelease();
    }

    @Override
    protected int sizeOf(BkCallArgs key, BkTextureRecord textureRecord) {
        return textureRecord.sizeOfMegaBytes();
    }
}
