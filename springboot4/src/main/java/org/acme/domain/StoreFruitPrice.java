package org.acme.domain;

import java.math.BigDecimal;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;

import com.fasterxml.jackson.annotation.JsonIgnore;
import org.hibernate.annotations.Cache;
import org.hibernate.annotations.CacheConcurrencyStrategy;
import org.hibernate.annotations.Fetch;
import org.hibernate.annotations.FetchMode;

@Entity
@Table(name = "store_fruit_prices")
public class StoreFruitPrice {
  @EmbeddedId
  @JsonIgnore
  private StoreFruitPriceId id;

  @MapsId("storeId")
  @ManyToOne(fetch = FetchType.EAGER, optional = false)
  @JoinColumn(name = "store_id", nullable = false)
  @Fetch(FetchMode.SELECT)
  @Cache(usage = CacheConcurrencyStrategy.NONSTRICT_READ_WRITE)
  private Store store;

  @MapsId("fruitId")
  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "fruit_id", nullable = false)
  @JsonIgnore
  private Fruit fruit;

  @NotNull
  @DecimalMin(value = "0.00", message = "Price must be >= 0")
  @Digits(integer = 10, fraction = 2)
  @Column(nullable = false, precision = 12, scale = 2)
  private BigDecimal price;

  public StoreFruitPrice() {}

  public StoreFruitPrice(Store store, Fruit fruit, BigDecimal price) {
    this.store = store;
    this.fruit = fruit;
    this.price = price;
    this.id = new StoreFruitPriceId(store, fruit);
  }

  public StoreFruitPriceId getId() { return id; }
  public void setId(StoreFruitPriceId id) { this.id = id; }

  public Store getStore() { return store; }
  public void setStore(Store store) {
    this.store = store;
    this.id = new StoreFruitPriceId((store != null) ? store.getId() : null,
        (this.id != null) ? this.id.fruitId() : null);
  }

  public Fruit getFruit() { return fruit; }
  public void setFruit(Fruit fruit) {
    this.fruit = fruit;
    this.id = new StoreFruitPriceId((this.id != null) ? this.id.storeId() : null,
        (fruit != null) ? fruit.getId() : null);
  }

  public BigDecimal getPrice() { return price; }
  public void setPrice(BigDecimal price) { this.price = price; }

}
