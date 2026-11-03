package org.acme;

import org.apache.coyote.AbstractProtocol;
import org.apache.coyote.http11.AbstractHttp11Protocol;
import org.apache.tomcat.util.net.AbstractEndpoint;

import org.springframework.aot.hint.MemberCategory;
import org.springframework.aot.hint.RuntimeHints;
import org.springframework.aot.hint.RuntimeHintsRegistrar;

public class TomcatRuntimeHints implements RuntimeHintsRegistrar {
  @Override
  public void registerHints(RuntimeHints hints, ClassLoader classLoader) {
    hints.reflection()
         .registerType(AbstractHttp11Protocol.class, MemberCategory.INVOKE_PUBLIC_METHODS)
         .registerType(AbstractProtocol.class, MemberCategory.INVOKE_PUBLIC_METHODS)
         .registerType(AbstractEndpoint.class, MemberCategory.INVOKE_PUBLIC_METHODS);
  }
}
