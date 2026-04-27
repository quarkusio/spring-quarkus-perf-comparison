using Dotnet10.Data;
using Dotnet10.Domain;
using Microsoft.EntityFrameworkCore;

namespace Dotnet10.Repository;

/// <summary>
/// EF Core implementation of IFruitRepository.
/// Equivalent to FruitRepository extends PanacheRepository&lt;Fruit&gt; in the Quarkus project.
/// Eager loading of StorePrices and their Stores mirrors Hibernate FetchType.EAGER / FetchMode.SELECT.
/// </summary>
public class FruitRepository(AppDbContext context) : IFruitRepository
{
    public async Task<List<Fruit>> ListAllAsync() =>
        await context.Fruits
            .Include(f => f.StorePrices)
            .ThenInclude(sp => sp.Store)
            .OrderBy(f => f.Id)
            .ToListAsync();

    public async Task<Fruit?> FindByNameAsync(string name) =>
        await context.Fruits
            .Include(f => f.StorePrices)
            .ThenInclude(sp => sp.Store)
            .FirstOrDefaultAsync(f => f.Name == name);

    public async Task PersistAsync(Fruit fruit)
    {
        context.Fruits.Add(fruit);
        await context.SaveChangesAsync();
    }
}
