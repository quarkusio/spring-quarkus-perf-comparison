using System.ComponentModel.DataAnnotations;

namespace Dotnet10.Dto;

/// <summary>DTO for a store-specific fruit price. Equivalent to StoreFruitPriceDTO record in the Quarkus project.</summary>
public record StoreFruitPriceDto(
    StoreDto Store,

    [property: Range(0, float.MaxValue, ErrorMessage = "Price must be >= 0")]
    float Price
);
