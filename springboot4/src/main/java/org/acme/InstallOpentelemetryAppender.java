package org.acme;

import org.springframework.beans.factory.InitializingBean;
import org.springframework.stereotype.Component;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.instrumentation.logback.appender.v1_0.OpenTelemetryAppender;

/**
 * Taken from https://spring.io/blog/2025/11/18/opentelemetry-with-spring-boot#exporting-logs
 */
@Component
class InstallOpentelemetryAppender implements InitializingBean {
    private final OpenTelemetry openTelemetry;

    InstallOpentelemetryAppender(OpenTelemetry openTelemetry) {
        this.openTelemetry = openTelemetry;
    }

    @Override
    public void afterPropertiesSet() {
        OpenTelemetryAppender.install(this.openTelemetry);
    }
}
