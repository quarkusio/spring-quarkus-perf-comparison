package org.acme.rest;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.acme.ContainersConfig;
import org.acme.domain.Address;
import org.acme.domain.Fruit;
import org.acme.domain.Store;
import org.acme.domain.StoreFruitPrice;
import org.acme.repository.FruitRepository;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@Import(ContainersConfig.class)
class FruitControllerTests {
  @Autowired
  MockMvc mockMvc;

  @MockitoBean
  FruitRepository fruitRepository;

  private static Fruit createFruit() {
    var price = BigDecimal.valueOf(1.29);
    var store = new Store(1L, "Some Store", new Address("123 Some St", "Some City", "USA"), "USD");
    var fruit = new Fruit(1L, "Apple", "Hearty Fruit");
    fruit.setStorePrices(List.of(new StoreFruitPrice(store, fruit, price)));

    return fruit;
  }

  @Test
  void getAll() throws Exception {
    var fruit = createFruit();
    var fruitStorePrice = fruit.getStorePrices().getFirst();
    var store = fruitStorePrice.getStore();

    Mockito.when(this.fruitRepository.findAll())
        .thenReturn(List.of(fruit));

    this.mockMvc.perform(get("/fruits"))
        .andExpect(status().isOk())
        .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
        .andExpect(jsonPath("$.size()").value(1))
        .andExpect(jsonPath("[0].id").value(1))
        .andExpect(jsonPath("[0].name").value("Apple"))
        .andExpect(jsonPath("[0].description").value("Hearty Fruit"))
        .andExpect(jsonPath("[0].description").value("Hearty Fruit"))
        .andExpect(jsonPath("[0].storePrices[0].price").value(fruitStorePrice.getPrice().floatValue()))
        .andExpect(jsonPath("[0].storePrices[0].store.name").value(store.getName()))
        .andExpect(jsonPath("[0].storePrices[0].store.address.address").value(store.getAddress().address()))
        .andExpect(jsonPath("[0].storePrices[0].store.address.city").value(store.getAddress().city()))
        .andExpect(jsonPath("[0].storePrices[0].store.address.country").value(store.getAddress().country()))
        .andExpect(jsonPath("[0].storePrices[0].store.currency").value(store.getCurrency()));

    Mockito.verify(this.fruitRepository).findAll();
    Mockito.verifyNoMoreInteractions(this.fruitRepository);
  }

  @Test
  void getFruitFound() throws Exception {
    var fruit = createFruit();
    var fruitStorePrice = fruit.getStorePrices().getFirst();
    var store = fruitStorePrice.getStore();

    Mockito.when(this.fruitRepository.findByName("Apple"))
        .thenReturn(Optional.of(fruit));

    this.mockMvc.perform(get("/fruits/Apple"))
        .andExpect(status().isOk())
        .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
        .andExpect(jsonPath("id").value(1))
        .andExpect(jsonPath("name").value("Apple"))
        .andExpect(jsonPath("description").value("Hearty Fruit"))
        .andExpect(jsonPath("storePrices[0].price").value(fruitStorePrice.getPrice().floatValue()))
        .andExpect(jsonPath("storePrices[0].store.name").value(store.getName()))
        .andExpect(jsonPath("storePrices[0].store.address.address").value(store.getAddress().address()))
        .andExpect(jsonPath("storePrices[0].store.address.city").value(store.getAddress().city()))
        .andExpect(jsonPath("storePrices[0].store.address.country").value(store.getAddress().country()))
        .andExpect(jsonPath("storePrices[0].store.currency").value(store.getCurrency()));

    Mockito.verify(this.fruitRepository).findByName("Apple");
    Mockito.verifyNoMoreInteractions(this.fruitRepository);
  }

  @Test
  void getFruitNotFound() throws Exception {
    Mockito.when(this.fruitRepository.findByName("Apple"))
        .thenReturn(Optional.empty());

    this.mockMvc.perform(get("/fruits/Apple"))
        .andExpect(status().isNotFound());

    Mockito.verify(this.fruitRepository).findByName("Apple");
    Mockito.verifyNoMoreInteractions(this.fruitRepository);
  }

  @Test
  void addFruit() throws Exception {
    Mockito.when(this.fruitRepository.save(Mockito.any(Fruit.class)))
        .thenReturn(new Fruit(1L, "Grapefruit", "Summer fruit"));

    this.mockMvc.perform(
            post("/fruits")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"Grapefruit\",\"description\":\"Summer fruit\"}")
        )
        .andExpect(status().isOk())
        .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
        .andExpect(jsonPath("name").value("Grapefruit"))
        .andExpect(jsonPath("description").value("Summer fruit"));

    Mockito.verify(this.fruitRepository).save(Mockito.any(Fruit.class));
    Mockito.verifyNoMoreInteractions(this.fruitRepository);
  }
}
