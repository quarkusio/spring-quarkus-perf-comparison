package org.acme;

import org.acme.domain.StoreFruitPriceId;
import org.hibernate.cache.internal.BasicCacheKeyImplementation;
import org.hibernate.cache.jcache.internal.JCacheRegionFactory;
import org.hibernate.cache.spi.entry.StandardCacheEntryImpl;
import org.hibernate.cache.spi.support.AbstractReadWriteAccess.Item;

import org.springframework.aot.hint.MemberCategory;
import org.springframework.aot.hint.RuntimeHints;
import org.springframework.aot.hint.RuntimeHintsRegistrar;

public class CacheRuntimeHints implements RuntimeHintsRegistrar {
    @Override
    public void registerHints(RuntimeHints hints, ClassLoader classLoader) {
        hints.reflection()
            .registerType(JCacheRegionFactory.class,
                MemberCategory.INVOKE_DECLARED_CONSTRUCTORS,
                MemberCategory.INVOKE_DECLARED_METHODS);

        // Hibernate 2nd-level cache with JCache/Ehcache uses Java serialization for cache keys.
        // In GraalVM native image we must explicitly register Serializable types.
        // This resolves: UnsupportedFeatureError for BasicCacheKeyImplementation
        hints.serialization().registerType(BasicCacheKeyImplementation.class)

        // Additional common types used by cache keys/values
            .registerType(Long.class)
            .registerType(String.class)
            .registerType(Integer.class)
            .registerType(Boolean.class)
            // Domain IDs or custom key classes (used in cache keys/values)
            .registerType(StoreFruitPriceId.class)
            // Hibernate L2 cache value entry type
            .registerType(StandardCacheEntryImpl.class)
            .registerType(Item.class);
        // If more classes are reported by native-image at runtime, register them here similarly.
    }
}