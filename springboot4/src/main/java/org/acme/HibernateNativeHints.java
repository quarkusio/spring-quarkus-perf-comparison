package org.acme;

import org.springframework.aot.hint.MemberCategory;
import org.springframework.aot.hint.RuntimeHints;
import org.springframework.aot.hint.RuntimeHintsRegistrar;

public class HibernateNativeHints implements RuntimeHintsRegistrar {
  @Override
  public void registerHints(RuntimeHints hints, ClassLoader classLoader) {
    hints.reflection().registerTypeIfPresent(classLoader,
        "org.hibernate.engine.internal.NaturalIdLogging_$logger",
        MemberCategory.INVOKE_PUBLIC_CONSTRUCTORS);
  }
}
