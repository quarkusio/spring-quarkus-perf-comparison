using Dotnet10.Domain;
using Dotnet10.Dto;

namespace Dotnet10.Mapping;

/// <summary>Static mapper for Fruit ↔ FruitDto. Equivalent to FruitMapper in the Quarkus project.</summary>
public static class FruitMapper
{
    public static FruitDto? Map(Fruit? fruit)
    {
        if (fruit is null)
            return null;

        var storePrices = fruit.StorePrices
            .Select(StoreFruitPriceMapper.Map)
            .OfType<StoreFruitPriceDto>()
            .ToList();

        return new FruitDto(fruit.Id, fruit.Name, fruit.Description, storePrices);
    }

    public static Fruit? Map(FruitDto? dto)
    {
        if (dto is null)
            return null;

        return new Fruit { Name = dto.Name, Description = dto.Description };
    }
}
