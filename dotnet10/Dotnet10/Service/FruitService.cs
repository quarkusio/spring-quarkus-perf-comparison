using Dotnet10.Dto;
using Dotnet10.Mapping;
using Dotnet10.Repository;

namespace Dotnet10.Service;

/// <summary>
/// Application service for Fruit operations.
/// Equivalent to @ApplicationScoped FruitService in the Quarkus project.
/// Transaction management is handled by the repository (SaveChangesAsync).
/// </summary>
public class FruitService(IFruitRepository fruitRepository)
{
    /// <summary>Returns all fruits as DTOs. Equivalent to getAllFruits() @Transactional(SUPPORTS).</summary>
    public async Task<List<FruitDto>> GetAllFruitsAsync() =>
        [.. (await fruitRepository.ListAllAsync())
            .Select(FruitMapper.Map)
            .OfType<FruitDto>()];

    /// <summary>
    /// Finds a fruit by name. Equivalent to getFruitByName() @Transactional(SUPPORTS).
    /// Returns null instead of Optional.empty() – idiomatic C# nullable reference type.
    /// </summary>
    public async Task<FruitDto?> GetFruitByNameAsync(string name)
    {
        var fruit = await fruitRepository.FindByNameAsync(name);
        return fruit is null ? null : FruitMapper.Map(fruit);
    }

    /// <summary>Creates and persists a new fruit. Equivalent to createFruit() @Transactional.</summary>
    public async Task<FruitDto> CreateFruitAsync(FruitDto fruitDto)
    {
        var fruit = FruitMapper.Map(fruitDto)!;
        await fruitRepository.PersistAsync(fruit);
        return FruitMapper.Map(fruit)!;
    }
}
