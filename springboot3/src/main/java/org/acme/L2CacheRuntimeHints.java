package org.acme;

import org.hibernate.cache.jcache.internal.JCacheRegionFactory;

import org.springframework.aot.hint.MemberCategory;
import org.springframework.aot.hint.RuntimeHints;
import org.springframework.aot.hint.RuntimeHintsRegistrar;

import com.github.benmanes.caffeine.jcache.spi.CaffeineCachingProvider;

public class L2CacheRuntimeHints implements RuntimeHintsRegistrar {
    @Override
    public void registerHints(RuntimeHints hints, ClassLoader classLoader) {
        var reflectionHints = hints.reflection();

        // Register JCache region factory for Hibernate L2 cache
        reflectionHints.registerType(JCacheRegionFactory.class,
                MemberCategory.INVOKE_DECLARED_CONSTRUCTORS,
                MemberCategory.INVOKE_DECLARED_METHODS);

        // Register Caffeine JCache provider for GraalVM native image
        reflectionHints.registerType(CaffeineCachingProvider.class,
                MemberCategory.INVOKE_DECLARED_CONSTRUCTORS,
                MemberCategory.INVOKE_DECLARED_METHODS);

        // Note: With Caffeine store-by-reference, serialization is not needed.
        // Cache stores references to objects directly in memory without serialization overhead.
        // Caches are configured programmatically in L2CacheConfiguration, no config file needed.
    }
}