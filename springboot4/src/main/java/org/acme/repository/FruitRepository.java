package org.acme.repository;

import java.util.List;
import java.util.Optional;

import org.acme.domain.Fruit;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.transaction.annotation.Propagation.SUPPORTS;

public interface FruitRepository extends JpaRepository<Fruit, Long> {

    @Transactional(propagation = SUPPORTS, readOnly = true)
    Optional<Fruit> findByName(String name);

    @Transactional(propagation = SUPPORTS, readOnly = true)
    List<Fruit> findAll();
}
