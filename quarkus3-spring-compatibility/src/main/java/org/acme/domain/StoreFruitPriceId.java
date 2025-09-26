package org.acme.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
public record StoreFruitPriceId(
    @Column(nullable = false) Long storeId,
    @Column(nullable = false) Long fruitId
) {

  public StoreFruitPriceId(Store store, Fruit fruit) {
    this((store != null) ? store.getId() : null, (fruit != null) ? fruit.getId() : null);
  }

  // JPA needs a no-arg constructor; records don't have it, but most providers support record components.
  // If your JPA provider requires, keep a synthetic no-arg constructor:
//  public StoreFruitPriceId() {
//    this(null, null);
//  }
}
