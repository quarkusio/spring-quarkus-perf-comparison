using Dotnet10.Domain;

namespace Dotnet10.Repository;

/// <summary>
/// Repository contract for Fruit. Extracted as an interface to allow faking in unit tests.
/// Equivalent to PanacheRepository&lt;Fruit&gt; in the Quarkus project.
/// </summary>
public interface IFruitRepository
{
    Task<List<Fruit>> ListAllAsync();
    Task<Fruit?> FindByNameAsync(string name);
    Task PersistAsync(Fruit fruit);
}
