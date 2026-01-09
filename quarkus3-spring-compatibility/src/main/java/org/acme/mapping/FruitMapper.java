package org.acme.mapping;

import java.util.Objects;

import org.acme.domain.Fruit;
import org.acme.dto.FruitDTO;

public final class FruitMapper {
  private FruitMapper() {}

  public static FruitDTO map(Fruit fruit) {
    if (fruit == null) {
      return null;
    }

    var prices = fruit.getStorePrices();
    var storePrices = (prices != null) ?
        prices.stream()
            .map(StoreFruitPriceMapper::map)
            .filter(Objects::nonNull)
            .toList() :
        null;

    return new FruitDTO(
        fruit.getId(),
        fruit.getName(),
        fruit.getDescription(),
        storePrices
    );
  }

  public static Fruit map(FruitDTO fruitDTO) {
    if (fruitDTO == null) {
      return null;
    }

    var fruit = new Fruit();
    fruit.setName(fruitDTO.name());
    fruit.setDescription(fruitDTO.description());

    // The rest of the relationships aren't built out yet

    return fruit;
  }
}
