package org.acme.e2e;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.List;

import jakarta.inject.Inject;

import org.acme.ContainersConfig;
import org.acme.dto.FruitDTO;
import org.acme.rest.FruitController;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.Test;

import io.micronaut.http.HttpStatus;
import io.micronaut.test.extensions.junit5.annotation.MicronautTest;

@MicronautTest(transactional = true, rollback = true)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class FruitControllerEndToEndTest extends ContainersConfig {

  @Inject
  FruitController fruitController;

  @Test
  void getAll() {
    List<FruitDTO> fruits = this.fruitController.getAll();

    assertThat(fruits).hasSize(10);
    assertThat(fruits.getFirst().id()).isGreaterThanOrEqualTo(1L);
    assertThat(fruits.getFirst().name()).isEqualTo("Apple");
    assertThat(fruits.getFirst().description()).isEqualTo("Hearty fruit");
    assertThat(fruits.getFirst().storePrices().getFirst().price()).isEqualByComparingTo(BigDecimal.valueOf(1.29));
    assertThat(fruits.getFirst().storePrices().getFirst().store().name()).isEqualTo("Store 1");
    assertThat(fruits.getFirst().storePrices().getFirst().store().address().address()).isEqualTo("123 Main St");
    assertThat(fruits.getFirst().storePrices().getFirst().store().address().city()).isEqualTo("Anytown");
    assertThat(fruits.getFirst().storePrices().getFirst().store().address().country()).isEqualTo("USA");
    assertThat(fruits.getFirst().storePrices().getFirst().store().currency()).isEqualTo("USD");
  }

  @Test
  void getFruitFound() {
    var response = this.fruitController.getFruit("Apple");
    FruitDTO body = response.body();

    assertThat(response)
        .returns(HttpStatus.OK, r -> r.status());
    assertThat(body)
        .isNotNull()
        .returns("Apple", FruitDTO::name)
        .returns("Hearty fruit", FruitDTO::description)
        .satisfies(fruit -> assertThat(fruit.id()).isGreaterThanOrEqualTo(1L))
        .satisfies(fruit -> assertThat(fruit.storePrices().getFirst().price()).isEqualByComparingTo(BigDecimal.valueOf(1.29)))
        .satisfies(fruit -> assertThat(fruit.storePrices().getFirst().store().name()).isEqualTo("Store 1"))
        .satisfies(fruit -> assertThat(fruit.storePrices().getFirst().store().address().address()).isEqualTo("123 Main St"))
        .satisfies(fruit -> assertThat(fruit.storePrices().getFirst().store().address().city()).isEqualTo("Anytown"))
        .satisfies(fruit -> assertThat(fruit.storePrices().getFirst().store().address().country()).isEqualTo("USA"))
        .satisfies(fruit -> assertThat(fruit.storePrices().getFirst().store().currency()).isEqualTo("USD"));
  }

  @Test
  void getFruitNotFound() {
    var response = this.fruitController.getFruit("XXXX");
    assertThat(response)
        .returns(HttpStatus.NOT_FOUND, r -> r.status())
        .returns(null, r -> r.body());
  }
}
