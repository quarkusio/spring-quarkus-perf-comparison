package org.acme;

import javax.sql.DataSource;

import org.springframework.beans.BeansException;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.context.annotation.Configuration;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.instrumentation.jdbc.datasource.OpenTelemetryDataSource;

@Configuration
public class DataSourceConfig implements BeanPostProcessor {
    private final ObjectProvider<OpenTelemetry> openTelemetryProvider;

    public DataSourceConfig(ObjectProvider<OpenTelemetry> openTelemetryProvider) {
        this.openTelemetryProvider = openTelemetryProvider;
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        if ((bean instanceof DataSource) && !(bean instanceof OpenTelemetryDataSource)) {
            OpenTelemetry openTelemetry = openTelemetryProvider.getIfAvailable();
            if (openTelemetry != null) {
                return new OpenTelemetryDataSource((DataSource) bean, openTelemetry);
            }
        }

        return bean;
    }
}
