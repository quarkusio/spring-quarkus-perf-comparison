package org.acme;

import javax.sql.DataSource;

import org.springframework.boot.jdbc.autoconfigure.DataSourceProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.instrumentation.jdbc.datasource.OpenTelemetryDataSource;

@Configuration
public class DataSourceConfig {
    @Bean
    public DataSource dataSource(DataSourceProperties properties, OpenTelemetry openTelemetry) {
        var dataSource = properties.initializeDataSourceBuilder().build();
        return new OpenTelemetryDataSource(dataSource, openTelemetry);
    }
}
