using System.ComponentModel.DataAnnotations;

namespace Dotnet10.Dto;

/// <summary>
/// DTO for Address. Equivalent to AddressDTO record in the Quarkus project.
/// The <see cref="Address"/> property serialises to JSON key "address" (camelCase),
/// matching the Quarkus response shape expected by tests.
/// Validation is enforced by ASP.NET Core model validation (equivalent to Jakarta Bean Validation).
/// </summary>
public record AddressDto(
    [property: Required(ErrorMessage = "Address is mandatory")]
    string Address,

    [property: Required(ErrorMessage = "City is mandatory")]
    string City,

    [property: Required(ErrorMessage = "Country is mandatory")]
    string Country
);
