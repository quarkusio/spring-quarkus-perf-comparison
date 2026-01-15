package org.acme.service;

import java.util.List;
import java.util.Optional;

import jakarta.transaction.Transactional;

import org.acme.dto.FruitDTO;
import org.acme.mapping.FruitMapper;
import org.acme.repository.FruitRepository;

import org.springframework.stereotype.Service;

@Service
public class FruitService {
  private final FruitRepository fruitRepository;

  public FruitService(FruitRepository fruitRepository) {
    this.fruitRepository = fruitRepository;
  }

  public List<FruitDTO> getAllFruits() {
    return this.fruitRepository.findAll().stream()
        .map(FruitMapper::map)
        .toList();
  }

  public Optional<FruitDTO> getFruitByName(String name) {
    return this.fruitRepository.findByName(name)
        .map(FruitMapper::map);
  }

  @Transactional
  public FruitDTO createFruit(FruitDTO fruitDTO) {
    var fruit = FruitMapper.map(fruitDTO);
    var savedFruit = this.fruitRepository.save(fruit);

    return FruitMapper.map(savedFruit);
  }
}
