package org.acme.dto;

public record StoreFruitPriceDTO(StoreDTO store, float price) {
  public StoreFruitPriceDTO {
    if (price < 0) {
      throw new IllegalArgumentException("Price must be >= 0");
    }
  }
}
