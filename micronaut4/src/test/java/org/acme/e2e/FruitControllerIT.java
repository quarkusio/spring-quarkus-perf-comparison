package org.acme.e2e;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.inject.Inject;

import org.acme.ContainersConfig;
import org.acme.dto.FruitDTO;
import org.acme.rest.FruitController;
import org.acme.service.FruitService;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.Test;

import io.micronaut.http.HttpStatus;
import io.micronaut.test.extensions.junit5.annotation.MicronautTest;

@MicronautTest(transactional = true, rollback = true)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class FruitControllerIT extends ContainersConfig {

  @Inject
  FruitController fruitController;
  @Inject
  FruitService fruitService;

  @Test
  void addFruitAndRetrieveIt() {
    int initialCount = this.fruitController.getAll().size();

    String fruitName = "Pomelo-E2E";
    FruitDTO createdFruit = this.fruitService.createFruit(new FruitDTO(null, fruitName, "Exotic fruit", null));

    assertThat(createdFruit.id()).isGreaterThanOrEqualTo(1L);
    assertThat(createdFruit.name()).isEqualTo(fruitName);
    assertThat(createdFruit.description()).isEqualTo("Exotic fruit");

    assertThat(this.fruitController.getAll()).hasSize(initialCount + 1);

    var response = this.fruitController.getFruit(fruitName);
    assertThat(response)
        .returns(HttpStatus.OK, r -> r.status());
    assertThat(response.body())
        .isNotNull()
        .returns(fruitName, FruitDTO::name)
        .returns("Exotic fruit", FruitDTO::description)
        .satisfies(fruit -> assertThat(fruit.id()).isGreaterThanOrEqualTo(1L));
  }
}
