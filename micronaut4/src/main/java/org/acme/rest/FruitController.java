package org.acme.rest;

import java.util.List;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;

import jakarta.validation.Valid;

import org.acme.dto.FruitDTO;
import org.acme.service.FruitService;

@Controller("/fruits")
public class FruitController {
  private final FruitService fruitService;

  public FruitController(FruitService fruitService) {
    this.fruitService = fruitService;
  }

  @Get(produces = MediaType.APPLICATION_JSON)
  public List<FruitDTO> getAll() {
    return this.fruitService.getAllFruits();
  }

  @Get(uri = "/{name}", produces = MediaType.APPLICATION_JSON)
  public HttpResponse<FruitDTO> getFruit(@PathVariable String name) {
    return this.fruitService.getFruitByName(name)
        .map(HttpResponse::ok)
        .orElseGet(HttpResponse::notFound);
  }

  @Post(consumes = MediaType.APPLICATION_JSON, produces = MediaType.APPLICATION_JSON)
  public FruitDTO addFruit(@Valid @Body FruitDTO fruit) {
    return this.fruitService.createFruit(fruit);
  }
}
