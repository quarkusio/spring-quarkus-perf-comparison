package org.acme.repository;

import static jakarta.transaction.Transactional.TxType.SUPPORTS;

import java.util.List;
import java.util.Optional;

import jakarta.transaction.Transactional;

import org.acme.domain.Fruit;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FruitRepository extends JpaRepository<Fruit, Long> {
	@Transactional(SUPPORTS)
  Optional<Fruit> findByName(String name);

  @Override
  @Transactional(SUPPORTS)
  List<Fruit> findAll();
}
