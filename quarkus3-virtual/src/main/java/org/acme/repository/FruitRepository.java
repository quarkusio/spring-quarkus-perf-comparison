package org.acme.repository;

import static jakarta.transaction.Transactional.TxType.SUPPORTS;

import java.util.Optional;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;

import org.acme.domain.Fruit;

import io.quarkus.hibernate.orm.panache.PanacheRepository;

@ApplicationScoped
public class FruitRepository implements PanacheRepository<Fruit> {
	@Transactional(SUPPORTS)
	public Optional<Fruit> findByName(String name) {
		return find("name", name).firstResultOptional();
	}
}
