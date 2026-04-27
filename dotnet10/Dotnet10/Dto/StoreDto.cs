using System.ComponentModel.DataAnnotations;

namespace Dotnet10.Dto;

/// <summary>DTO for Store. Equivalent to StoreDTO record in the Quarkus project.</summary>
public record StoreDto(
    long? Id,

    [property: Required(ErrorMessage = "Name is mandatory")]
    string Name,

    [property: Required(ErrorMessage = "Currency is mandatory")]
    string Currency,

    AddressDto? Address
);
