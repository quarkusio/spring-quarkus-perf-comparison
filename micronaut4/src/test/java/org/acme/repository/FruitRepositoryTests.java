package org.acme.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Optional;

import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import org.acme.ContainersConfig;
import org.acme.domain.Fruit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;

import io.micronaut.test.extensions.junit5.annotation.MicronautTest;

@MicronautTest(transactional = true, rollback = true)
@Transactional
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class FruitRepositoryTests extends ContainersConfig {
  @Inject
  FruitRepository fruitRepository;

  @Test
  void findByName() {
    this.fruitRepository.save(new Fruit(null, "Grapefruit", "Summer fruit"));

    Optional<Fruit> fruit = this.fruitRepository.findByName("Grapefruit");
    assertThat(fruit)
        .isNotNull()
        .isPresent()
        .get()
        .extracting(Fruit::getName, Fruit::getDescription)
        .containsExactly("Grapefruit", "Summer fruit");

    assertThat(fruit.get().getId())
        .isNotNull()
        .isGreaterThan(2L);
  }
}
