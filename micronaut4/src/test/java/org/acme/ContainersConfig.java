package org.acme;

import java.util.Map;

import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

import io.micronaut.test.support.TestPropertyProvider;

public abstract class ContainersConfig implements TestPropertyProvider {

  private static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>(DockerImageName.parse("postgres:17"));

  static {
    POSTGRES.start();
  }

  @Override
  public Map<String, String> getProperties() {
    return Map.of(
        "datasources.default.url", POSTGRES.getJdbcUrl(),
        "datasources.default.username", POSTGRES.getUsername(),
        "datasources.default.password", POSTGRES.getPassword(),
        "datasources.default.driverClassName", "org.postgresql.Driver",
        "datasources.default.schema-generate", "CREATE_DROP",
        "datasources.default.dialect", "POSTGRES",
        "jpa.default.properties.hibernate.hbm2ddl.auto", "create-drop");
  }
}
