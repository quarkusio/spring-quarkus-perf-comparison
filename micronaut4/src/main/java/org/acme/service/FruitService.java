package org.acme.service;

import static jakarta.transaction.Transactional.TxType.SUPPORTS;

import java.util.List;
import java.util.Optional;

import jakarta.inject.Singleton;
import jakarta.transaction.Transactional;

import org.acme.dto.FruitDTO;
import org.acme.mapping.FruitMapper;
import org.acme.repository.FruitRepository;

import io.opentelemetry.instrumentation.annotations.SpanAttribute;
import io.opentelemetry.instrumentation.annotations.WithSpan;

@Singleton
public class FruitService {
  private final FruitRepository fruitRepository;

  public FruitService(FruitRepository fruitRepository) {
    this.fruitRepository = fruitRepository;
  }

  @WithSpan("FruitService.getAllFruits")
  @Transactional(SUPPORTS)
  public List<FruitDTO> getAllFruits() {
    return this.fruitRepository.findAll().stream()
        .map(FruitMapper::map)
        .toList();
  }

  @WithSpan("FruitService.getFruitByName")
  @Transactional(SUPPORTS)
  public Optional<FruitDTO> getFruitByName(@SpanAttribute("arg.name") String name) {
    return this.fruitRepository.findByName(name)
        .map(FruitMapper::map);
  }

  @WithSpan("FruitService.createFruit")
  @Transactional
  public FruitDTO createFruit(@SpanAttribute("arg.fruit") FruitDTO fruitDTO) {
    var fruit = FruitMapper.map(fruitDTO);
    var savedFruit = this.fruitRepository.save(fruit);

    return FruitMapper.map(savedFruit);
  }
}
