package org.acme.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.server.observation.OpenTelemetryServerRequestObservationConvention;

import io.micrometer.core.instrument.Tags;
import io.micrometer.core.instrument.binder.jvm.convention.otel.OpenTelemetryJvmCpuMeterConventions;

/**
 * Taken from https://spring.io/blog/2025/11/18/opentelemetry-with-spring-boot#exporting-metrics
 */
@Configuration(proxyBeanMethods = false)
public class OpentelemetryConfiguration {

    @Bean
    OpenTelemetryServerRequestObservationConvention openTelemetryServerRequestObservationConvention() {
        return new OpenTelemetryServerRequestObservationConvention();
    }

    @Bean
    OpenTelemetryJvmCpuMeterConventions openTelemetryJvmCpuMeterConventions() {
        return new OpenTelemetryJvmCpuMeterConventions(Tags.empty());
    }
}
