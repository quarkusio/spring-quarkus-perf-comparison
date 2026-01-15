package org.acme.mapping;

import org.acme.domain.StoreFruitPrice;
import org.acme.dto.StoreFruitPriceDTO;

public final class StoreFruitPriceMapper {
  private StoreFruitPriceMapper() {}

  public static StoreFruitPriceDTO map(StoreFruitPrice storeFruitPrice) {
    if (storeFruitPrice == null) {
      return null;
    }

    return new StoreFruitPriceDTO(
        StoreMapper.map(storeFruitPrice.getStore()),
        storeFruitPrice.getPrice().floatValue()
    );
  }
}
