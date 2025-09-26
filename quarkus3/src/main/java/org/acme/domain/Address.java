package org.acme.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.validation.constraints.NotBlank;

@Embeddable
public record Address(
    @Column(nullable = false)
    @NotBlank(message = "Address is mandatory")
    String address,

    @Column(nullable = false)
    @NotBlank(message = "City is mandatory")
    String city,

    @Column(nullable = false)
    @NotBlank(message = "Country is mandatory")
    String country
) {}
