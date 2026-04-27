using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace Dotnet10.Domain;

/// <summary>
/// Embeddable address value object. Equivalent to @Embeddable Address in the Quarkus project.
/// </summary>
[Owned]
public record Address(
    [property: Required(ErrorMessage = "Address is mandatory")]
    string AddressLine,

    [property: Required(ErrorMessage = "City is mandatory")]
    string City,

    [property: Required(ErrorMessage = "Country is mandatory")]
    string Country
);
