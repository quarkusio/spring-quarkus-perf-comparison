package org.acme.dto;

import java.math.BigDecimal;

public record StoreFruitPriceDTO(StoreDTO store, BigDecimal price) {
  public StoreFruitPriceDTO {
    if ((price != null) && (price.signum() < 0)) {
      throw new IllegalArgumentException("Price must be >= 0");
    }
  }
}
