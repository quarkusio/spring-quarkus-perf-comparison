package org.acme;

import java.net.URI;

import javax.cache.CacheManager;
import javax.cache.Caching;
import javax.cache.spi.CachingProvider;

import org.springframework.boot.autoconfigure.orm.jpa.HibernatePropertiesCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.github.benmanes.caffeine.jcache.configuration.CaffeineConfiguration;
import com.github.benmanes.caffeine.jcache.spi.CaffeineCachingProvider;

@Configuration
public class L2CacheConfiguration {
    @Bean
    public CacheManager jCacheManager() {
        CachingProvider provider = Caching.getCachingProvider(CaffeineCachingProvider.class.getName());
        CacheManager cacheManager = provider.getCacheManager(URI.create("caffeine://default"), getClass().getClassLoader());
        
        // Create default cache configuration with store-by-reference
        createCache(cacheManager, "default", createCaffeineConfig());
        
        // Create cache for Store entity with expiration and size limits
        createCache(cacheManager, "org.acme.domain.Store", 
            createCaffeineConfig());
        
        // Create cache for StoreFruitPrice.store association with expiration and size limits
        createCache(cacheManager, "org.acme.domain.StoreFruitPrice.store", 
            createCaffeineConfig());
        
        return cacheManager;
    }
    
    private void createCache(CacheManager cacheManager, String cacheName, CaffeineConfiguration<Object, Object> config) {
        if (cacheManager.getCache(cacheName) == null) {
            cacheManager.createCache(cacheName, config);
        }
    }
    
    private CaffeineConfiguration<Object, Object> createCaffeineConfig() {
        var config = new CaffeineConfiguration<>();
        
        // Use store-by-reference (not store-by-value)
        config.setStoreByValue(false);
        
        return config;
    }
    
    @Bean
    public HibernatePropertiesCustomizer hibernatePropertiesCustomizer(CacheManager cacheManager) {
        return hibernateProperties -> {
            // Inject the programmatically created CacheManager into Hibernate
            hibernateProperties.put("hibernate.javax.cache.cache_manager", cacheManager);
        };
    }
}
