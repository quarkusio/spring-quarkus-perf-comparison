package org.acme.repository;

import static org.springframework.transaction.annotation.Propagation.SUPPORTS;

import java.util.List;
import java.util.Optional;

import org.acme.domain.Fruit;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface FruitRepository extends JpaRepository<Fruit, Long> {
	@Transactional(propagation = SUPPORTS, readOnly = true)
  Optional<Fruit> findByName(String name);

  @Override
  @Transactional(propagation = SUPPORTS, readOnly = true)
  List<Fruit> findAll();
}
