package org.acme.service;

import static org.springframework.transaction.annotation.Propagation.SUPPORTS;

import java.util.List;
import java.util.Optional;

import org.acme.dto.FruitDTO;
import org.acme.mapping.FruitMapper;
import org.acme.repository.FruitRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import io.opentelemetry.instrumentation.annotations.SpanAttribute;
import io.opentelemetry.instrumentation.annotations.WithSpan;

@Service
public class FruitService {
  private final FruitRepository fruitRepository;

  public FruitService(FruitRepository fruitRepository) {
    this.fruitRepository = fruitRepository;
  }

  @WithSpan("FruitService.getAllFruits")
  @Transactional(propagation = SUPPORTS, readOnly = true)
  public List<FruitDTO> getAllFruits() {
    return this.fruitRepository.findAll().stream()
        .map(FruitMapper::map)
        .toList();
  }

  @WithSpan("FruitService.getFruitByName")
  @Transactional(propagation = SUPPORTS, readOnly = true)
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
