package org.acme.repository;

import java.util.Optional;

import jakarta.enterprise.context.ApplicationScoped;

import org.acme.domain.Fruit;

import io.quarkus.hibernate.orm.panache.PanacheRepository;

@ApplicationScoped
public class FruitRepository implements PanacheRepository<Fruit> {
	public Optional<Fruit> findByName(String name) {
		return find("name", name).firstResultOptional();
	}
}
