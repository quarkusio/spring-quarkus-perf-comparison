using Dotnet10.Domain;
using Dotnet10.Dto;
using Dotnet10.Repository;
using Dotnet10.Service;
using Xunit;

namespace Dotnet10.Tests.Service;

/// <summary>
/// Unit tests for FruitService with a hand-written IFruitRepository fake.
///
/// Equivalent to @QuarkusTest FruitControllerTests in the Quarkus project.
/// The Quarkus tests exercise the HTTP layer via rest-assured, but the intent
/// is to verify that the business logic correctly maps domain objects to DTOs,
/// applies the right repository calls, and handles missing results. Testing
/// FruitService directly achieves the same coverage without any HTTP or framework
/// infrastructure, and without a dependency on Microsoft.AspNetCore.Mvc.Testing.
/// </summary>
public class FruitServiceTests
{
    // ── fake ──────────────────────────────────────────────────────────────────

    private sealed class FakeFruitRepository : IFruitRepository
    {
        public List<Fruit>? ListAllResult    { get; set; }
        public Fruit?       FindByNameResult { get; set; }

        public int     ListAllCalled    { get; private set; }
        public int     FindByNameCalled { get; private set; }
        public int     PersistCalled    { get; private set; }
        public string? FindByNameArg    { get; private set; }
        public Fruit?  PersistArg       { get; private set; }

        public Task<List<Fruit>> ListAllAsync()
        {
            ListAllCalled++;
            return Task.FromResult(ListAllResult
                ?? throw new InvalidOperationException("ListAllResult not configured"));
        }

        public Task<Fruit?> FindByNameAsync(string name)
        {
            FindByNameCalled++;
            FindByNameArg = name;
            return Task.FromResult(FindByNameResult);
        }

        public Task PersistAsync(Fruit fruit)
        {
            PersistCalled++;
            PersistArg = fruit;
            return Task.CompletedTask;
        }
    }

    // ── helpers ────────────────────────────────────────────────────────────────

    private static Fruit CreateFruit()
    {
        var store = new Store(1L, "Some Store", new Address("123 Some St", "Some City", "USA"), "USD");
        var fruit = new Fruit(1L, "Apple", "Hearty Fruit");
        fruit.StorePrices = [new StoreFruitPrice(store, fruit, 1.29m)];
        return fruit;
    }

    // ── tests ──────────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetAll()
    {
        var fruit = CreateFruit();
        var store = fruit.StorePrices.First().Store;
        var fake  = new FakeFruitRepository { ListAllResult = [fruit] };

        var dtos = await new FruitService(fake).GetAllFruitsAsync();

        Assert.Single(dtos);
        var dto = dtos[0];
        Assert.Equal(1L,            dto.Id);
        Assert.Equal("Apple",       dto.Name);
        Assert.Equal("Hearty Fruit", dto.Description);
        Assert.NotNull(dto.StorePrices);
        Assert.Single(dto.StorePrices);

        var priceDto = dto.StorePrices[0];
        Assert.Equal(1.29f,                    priceDto.Price);
        Assert.Equal(store.Name,               priceDto.Store.Name);
        Assert.Equal(store.Address.AddressLine, priceDto.Store.Address!.Address);
        Assert.Equal(store.Address.City,       priceDto.Store.Address!.City);
        Assert.Equal(store.Address.Country,    priceDto.Store.Address!.Country);
        Assert.Equal(store.Currency,           priceDto.Store.Currency);

        Assert.Equal(1, fake.ListAllCalled);
        Assert.Equal(0, fake.FindByNameCalled);
        Assert.Equal(0, fake.PersistCalled);
    }

    [Fact]
    public async Task GetFruitByNameFound()
    {
        var fruit = CreateFruit();
        var store = fruit.StorePrices.First().Store;
        var fake  = new FakeFruitRepository { FindByNameResult = fruit };

        var dto = await new FruitService(fake).GetFruitByNameAsync("Apple");

        Assert.NotNull(dto);
        Assert.Equal(1L,            dto.Id);
        Assert.Equal("Apple",       dto.Name);
        Assert.Equal("Hearty Fruit", dto.Description);

        var priceDto = dto.StorePrices![0];
        Assert.Equal(1.29f,                    priceDto.Price);
        Assert.Equal(store.Name,               priceDto.Store.Name);
        Assert.Equal(store.Address.AddressLine, priceDto.Store.Address!.Address);
        Assert.Equal(store.Address.City,       priceDto.Store.Address!.City);
        Assert.Equal(store.Address.Country,    priceDto.Store.Address!.Country);
        Assert.Equal(store.Currency,           priceDto.Store.Currency);

        Assert.Equal(1, fake.FindByNameCalled);
        Assert.Equal("Apple", fake.FindByNameArg);
        Assert.Equal(0, fake.ListAllCalled);
        Assert.Equal(0, fake.PersistCalled);
    }

    [Fact]
    public async Task GetFruitByNameNotFound()
    {
        var fake = new FakeFruitRepository { FindByNameResult = null };

        var dto = await new FruitService(fake).GetFruitByNameAsync("Apple");

        Assert.Null(dto);
        Assert.Equal(1, fake.FindByNameCalled);
        Assert.Equal("Apple", fake.FindByNameArg);
        Assert.Equal(0, fake.ListAllCalled);
        Assert.Equal(0, fake.PersistCalled);
    }

    [Fact]
    public async Task AddFruit()
    {
        var fake  = new FakeFruitRepository();
        var input = new FruitDto(null, "Grapefruit", "Summer fruit", null);

        var result = await new FruitService(fake).CreateFruitAsync(input);

        Assert.Equal("Grapefruit",  result.Name);
        Assert.Equal("Summer fruit", result.Description);
        Assert.Equal(1, fake.PersistCalled);
        Assert.NotNull(fake.PersistArg);
        Assert.Equal("Grapefruit", fake.PersistArg!.Name);
        Assert.Equal(0, fake.ListAllCalled);
        Assert.Equal(0, fake.FindByNameCalled);
    }
}
