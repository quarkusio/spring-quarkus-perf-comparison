package org.acme.service;

import java.util.List;
import java.util.Optional;

import org.acme.dto.FruitDTO;
import org.acme.mapping.FruitMapper;
import org.acme.repository.FruitRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class FruitService {
  private final FruitRepository fruitRepository;

  public FruitService(FruitRepository fruitRepository) {
    this.fruitRepository = fruitRepository;
  }

  @Transactional(readOnly = true)
  public List<FruitDTO> getAllFruits() {
    return this.fruitRepository.findAll().stream()
        .map(FruitMapper::map)
        .toList();
  }

  @Transactional(readOnly = true)
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
