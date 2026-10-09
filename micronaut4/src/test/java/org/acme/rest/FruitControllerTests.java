package org.acme.rest;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.acme.domain.Address;
import org.acme.domain.Fruit;
import org.acme.domain.Store;
import org.acme.domain.StoreFruitPrice;
import org.acme.dto.FruitDTO;
import org.acme.repository.FruitRepository;
import org.acme.service.FruitService;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
class FruitControllerTests {
  private final FruitRepository fruitRepository = Mockito.mock(FruitRepository.class);
  private final FruitController fruitController = new FruitController(new FruitService(this.fruitRepository));

  private static Fruit createFruit() {
    var price = BigDecimal.valueOf(1.29);
    var store = new Store(1L, "Some Store", new Address("123 Some St", "Some City", "USA"), "USD");
    var fruit = new Fruit(1L, "Apple", "Hearty Fruit");
    fruit.setStorePrices(List.of(new StoreFruitPrice(store, fruit, price)));

    return fruit;
  }

  @Test
  void getAll() throws Exception {
    var fruit = createFruit();
    var fruitStorePrice = fruit.getStorePrices().get(0);
    var store = fruitStorePrice.getStore();

    Mockito.when(this.fruitRepository.findAll())
        .thenReturn(List.of(fruit));

    List<FruitDTO> response = this.fruitController.getAll();
    assertThat(response).hasSize(1);
    assertThat(response.get(0).id()).isEqualTo(1L);
    assertThat(response.get(0).name()).isEqualTo("Apple");
    assertThat(response.get(0).description()).isEqualTo("Hearty Fruit");
    assertThat(response.get(0).storePrices().get(0).price()).isEqualByComparingTo(fruitStorePrice.getPrice());
    assertThat(response.get(0).storePrices().get(0).store().name()).isEqualTo(store.getName());
    assertThat(response.get(0).storePrices().get(0).store().address().address()).isEqualTo(store.getAddress().address());
    assertThat(response.get(0).storePrices().get(0).store().address().city()).isEqualTo(store.getAddress().city());
    assertThat(response.get(0).storePrices().get(0).store().address().country()).isEqualTo(store.getAddress().country());
    assertThat(response.get(0).storePrices().get(0).store().currency()).isEqualTo(store.getCurrency());

    Mockito.verify(this.fruitRepository).findAll();
    Mockito.verifyNoMoreInteractions(this.fruitRepository);
  }

  @Test
  void getFruitFound() throws Exception {
    var fruit = createFruit();
    var fruitStorePrice = fruit.getStorePrices().get(0);
    var store = fruitStorePrice.getStore();

    Mockito.when(this.fruitRepository.findByName("Apple"))
        .thenReturn(Optional.of(fruit));

    HttpResponse<FruitDTO> response = this.fruitController.getFruit("Apple");
    assertThat(response.status().getCode()).isEqualTo(HttpStatus.OK.getCode());
    FruitDTO body = response.body();
    assertThat(body).isNotNull();
    assertThat(body.id()).isEqualTo(1L);
    assertThat(body.name()).isEqualTo("Apple");
    assertThat(body.description()).isEqualTo("Hearty Fruit");
    assertThat(body.storePrices().get(0).price()).isEqualByComparingTo(fruitStorePrice.getPrice());
    assertThat(body.storePrices().get(0).store().name()).isEqualTo(store.getName());
    assertThat(body.storePrices().get(0).store().address().address()).isEqualTo(store.getAddress().address());
    assertThat(body.storePrices().get(0).store().address().city()).isEqualTo(store.getAddress().city());
    assertThat(body.storePrices().get(0).store().address().country()).isEqualTo(store.getAddress().country());
    assertThat(body.storePrices().get(0).store().currency()).isEqualTo(store.getCurrency());

    Mockito.verify(this.fruitRepository).findByName("Apple");
    Mockito.verifyNoMoreInteractions(this.fruitRepository);
  }

  @Test
  void getFruitNotFound() {
    Mockito.when(this.fruitRepository.findByName("Apple"))
        .thenReturn(Optional.empty());

    HttpResponse<FruitDTO> response = this.fruitController.getFruit("Apple");
    assertThat(response.status().getCode()).isEqualTo(HttpStatus.NOT_FOUND.getCode());

    Mockito.verify(this.fruitRepository).findByName("Apple");
    Mockito.verifyNoMoreInteractions(this.fruitRepository);
  }

  @Test
  void addFruit() throws Exception {
    Mockito.when(this.fruitRepository.save(Mockito.any(Fruit.class)))
        .thenReturn(new Fruit(1L, "Grapefruit", "Summer fruit"));

    FruitDTO response = this.fruitController.addFruit(new FruitDTO(null, "Grapefruit", "Summer fruit", null));
    assertThat(response.name()).isEqualTo("Grapefruit");
    assertThat(response.description()).isEqualTo("Summer fruit");

    Mockito.verify(this.fruitRepository).save(Mockito.any(Fruit.class));
    Mockito.verifyNoMoreInteractions(this.fruitRepository);
  }
}
