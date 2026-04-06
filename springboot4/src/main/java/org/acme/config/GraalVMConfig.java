package org.acme.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.ImportRuntimeHints;

@Configuration
@ImportRuntimeHints({ HibernateNativeHints.class, L2CacheRuntimeHints.class })
public class GraalVMConfig {
}
