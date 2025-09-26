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
}
