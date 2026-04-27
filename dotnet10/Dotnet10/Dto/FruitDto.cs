using System.ComponentModel.DataAnnotations;

namespace Dotnet10.Dto;

/// <summary>DTO for Fruit. Equivalent to FruitDTO record in the Quarkus project.</summary>
public record FruitDto(
    long? Id,

    [property: Required(ErrorMessage = "Name is mandatory")]
    string Name,

    string? Description,

    IReadOnlyList<StoreFruitPriceDto>? StorePrices = null)
{
    // Guarantee a non-null list for StorePrices – mirrors the null-coercion in the
    // Java compact constructor. C# positional records allow overriding a positional
    // property in the record body; the init accessor runs after the primary constructor.
    public IReadOnlyList<StoreFruitPriceDto> StorePrices { get; init; } = StorePrices ?? [];
}
