using Dotnet10.Domain;
using Dotnet10.Dto;

namespace Dotnet10.Mapping;

/// <summary>
/// Static mapper for StoreFruitPrice → StoreFruitPriceDto.
/// Equivalent to StoreFruitPriceMapper in the Quarkus project.
/// </summary>
public static class StoreFruitPriceMapper
{
    public static StoreFruitPriceDto? Map(StoreFruitPrice? storeFruitPrice) =>
        storeFruitPrice is null
            ? null
            : new StoreFruitPriceDto(
                StoreMapper.Map(storeFruitPrice.Store)!,
                (float)storeFruitPrice.Price);
}
