package org.acme.domain;

import java.util.StringJoiner;

import jakarta.persistence.Cacheable;
import jakarta.persistence.Column;
import jakarta.persistence.Embedded;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;

import org.hibernate.annotations.NaturalId;

@Entity
@Table(name = "stores")
@Cacheable
public class Store {
  @Id
  @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "stores_seq")
  @SequenceGenerator(name = "stores_seq", sequenceName = "stores_seq", allocationSize = 1)
  private Long id;

  @Column(nullable = false, unique = true)
  @NaturalId
  @NotBlank(message = "Name is mandatory")
  private String name;

  @Column(nullable = false)
  @NotBlank(message = "Currency is mandatory")
  private String currency;

  @Embedded
  private Address address;

  public Store() {}

  public Store(Long id, String name, Address address, String currency) {
    this.id = id;
    this.name = name;
    this.address = address;
    this.currency = currency;
  }

  public Long getId() { return id; }
  public void setId(Long id) { this.id = id; }

  public String getName() { return name; }
  public void setName(String name) { this.name = name; }

  public Address getAddress() { return address; }
  public void setAddress(Address address) { this.address = address; }

  public String getCurrency() {
    return currency;
  }

  public void setCurrency(String currency) {
    this.currency = currency;
  }

  @Override
  public String toString() {
    return new StringJoiner(", ", Store.class.getSimpleName() + "[", "]")
        .add("id=" + id)
        .add("name='" + name + "'")
        .add("address=" + address)
        .add("currency='" + currency + "'")
        .toString();
  }

}
