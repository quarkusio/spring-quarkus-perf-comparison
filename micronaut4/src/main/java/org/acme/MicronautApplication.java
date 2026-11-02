package org.acme;

import io.micronaut.runtime.Micronaut;

public final class MicronautApplication {
  private MicronautApplication() {
  }

  public static void main(String[] args) {
    Micronaut.run(MicronautApplication.class, args);
  }
}
