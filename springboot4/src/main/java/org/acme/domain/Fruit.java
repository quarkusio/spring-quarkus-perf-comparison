package org.acme.domain;

import java.util.List;
import java.util.StringJoiner;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;

import org.hibernate.annotations.NaturalId;

@Entity
@Table(name = "fruits")
public class Fruit {
  @Id
  @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "fruits_seq")
  @SequenceGenerator(name = "fruits_seq", sequenceName = "fruits_seq", allocationSize = 1)
  private Long id;

  @Column(nullable = false, unique = true)
  @NaturalId
  @NotBlank(message = "Name is mandatory")
  private String name;
  private String description;

  @OneToMany(mappedBy = "fruit")
  private List<StoreFruitPrice> storePrices;

  public Fruit() {
  }

  public Fruit(Long id, String name, String description) {
    this.id = id;
    this.name = name;
    this.description = description;
  }

  public Long getId() {
    return this.id;
  }

  public void setId(Long id) {
    this.id = id;
  }

  public String getName() {
    return this.name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public String getDescription() {
    return this.description;
  }

  public void setDescription(String description) {
    this.description = description;
  }

  public List<StoreFruitPrice> getStorePrices() {
    return storePrices;
  }

  public void setStorePrices(List<StoreFruitPrice> storePrices) {
    this.storePrices = storePrices;
  }

  @Override
  public String toString() {
    return new StringJoiner(", ", Fruit.class.getSimpleName() + "[", "]")
        .add("id=" + this.id)
        .add("name='" + this.name + "'")
        .add("description='" + this.description + "'")
        .add("storePrices=" + this.storePrices)
        .toString();
  }

}
