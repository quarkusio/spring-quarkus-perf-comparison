using System.Net;
using System.Net.Http.Json;
using Dotnet10.Dto;
using Xunit;

namespace Dotnet10.Tests.E2e;

/// <summary>
/// End-to-end tests that exercise the running application over HTTP.
///
/// Equivalent to @QuarkusIntegrationTest FruitControllerIT in the Quarkus project:
/// the application runs as a separate process and the tests call it via plain HTTP.
///
/// Prerequisites:
///   1. PostgreSQL running on localhost:5432 (database: fruits, user: fruits, password: fruits)
///   2. Database seeded from import.sql
///   3. Application running: dotnet run --project Dotnet10 -c Release
///
/// All tests are fully independent and require no ordering.
/// AddFruit captures the count before and after, so it is safe to run in any order.
/// </summary>
public class FruitControllerEndToEndTest : IDisposable
{
    private readonly HttpClient _client = new() { BaseAddress = new Uri("http://localhost:8080") };

    public void Dispose() => _client.Dispose();

    [Fact]
    public async Task GetAll()
    {
        var response = await _client.GetAsync("/fruits", TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var fruits = await response.Content.ReadFromJsonAsync<List<FruitDto>>(TestContext.Current.CancellationToken);
        Assert.NotNull(fruits);
        Assert.True(fruits.Count >= 10);

        // Apple is always first (ordered by ID, seeded first)
        var apple = fruits.First(f => f.Name == "Apple");
        Assert.Equal("Hearty fruit", apple.Description);
        Assert.Equal(1.29f,      apple.StorePrices![0].Price);
        Assert.Equal("Store 1",      apple.StorePrices[0].Store.Name);
        Assert.Equal("123 Main St",  apple.StorePrices[0].Store.Address!.Address);
        Assert.Equal("Anytown",      apple.StorePrices[0].Store.Address!.City);
        Assert.Equal("USA",          apple.StorePrices[0].Store.Address!.Country);
        Assert.Equal("USD",          apple.StorePrices[0].Store.Currency);
        Assert.Equal(2.49f,      apple.StorePrices[1].Price);
        Assert.Equal("Store 2",      apple.StorePrices[1].Store.Name);
        Assert.Equal("456 Main St",  apple.StorePrices[1].Store.Address!.Address);
        Assert.Equal("Paris",        apple.StorePrices[1].Store.Address!.City);
        Assert.Equal("France",       apple.StorePrices[1].Store.Address!.Country);
        Assert.Equal("EUR",          apple.StorePrices[1].Store.Currency);

        var pear = fruits.First(f => f.Name == "Pear");
        Assert.Equal("Juicy fruit", pear.Description);
        Assert.Equal(0.99f, pear.StorePrices![0].Price);
        Assert.Equal("Store 1", pear.StorePrices[0].Store.Name);
        Assert.Equal(1.19f, pear.StorePrices[1].Price);
        Assert.Equal("Store 2", pear.StorePrices[1].Store.Name);

        var banana = fruits.First(f => f.Name == "Banana");
        Assert.Equal("Tropical yellow fruit", banana.Description);
        Assert.Equal(0.59f, banana.StorePrices![0].Price);
        Assert.Equal("Store 1", banana.StorePrices[0].Store.Name);
        Assert.Equal(0.89f, banana.StorePrices[1].Price);
        Assert.Equal("Store 2", banana.StorePrices[1].Store.Name);

        var orange = fruits.First(f => f.Name == "Orange");
        Assert.Equal("Citrus fruit rich in vitamin C", orange.Description);
        Assert.Equal(1.19f, orange.StorePrices![0].Price);
        Assert.Equal("Store 1", orange.StorePrices[0].Store.Name);
        Assert.Equal(1.79f, orange.StorePrices[1].Price);
        Assert.Equal("Store 2", orange.StorePrices[1].Store.Name);

        var strawberry = fruits.First(f => f.Name == "Strawberry");
        Assert.Equal("Sweet red berry", strawberry.Description);
        Assert.Equal(3.99f, strawberry.StorePrices![0].Price);
        Assert.Equal("Store 1",     strawberry.StorePrices[0].Store.Name);
        Assert.Equal(3.49f, strawberry.StorePrices[1].Price);
        Assert.Equal("Store 3",     strawberry.StorePrices[1].Store.Name);
        Assert.Equal("789 Oak Ave", strawberry.StorePrices[1].Store.Address!.Address);
        Assert.Equal("London",      strawberry.StorePrices[1].Store.Address!.City);
        Assert.Equal("UK",          strawberry.StorePrices[1].Store.Address!.Country);
        Assert.Equal("GBP",         strawberry.StorePrices[1].Store.Currency);

        var mango = fruits.First(f => f.Name == "Mango");
        Assert.Equal("Exotic tropical fruit", mango.Description);
        Assert.Equal(2.99f, mango.StorePrices![0].Price);
        Assert.Equal("Store 2", mango.StorePrices[0].Store.Name);
        Assert.Equal(3.99f, mango.StorePrices[1].Price);
        Assert.Equal("Store 6",    mango.StorePrices[1].Store.Name);
        Assert.Equal("888 Pine St", mango.StorePrices[1].Store.Address!.Address);
        Assert.Equal("Sydney",     mango.StorePrices[1].Store.Address!.City);
        Assert.Equal("Australia",  mango.StorePrices[1].Store.Address!.Country);
        Assert.Equal("AUD",        mango.StorePrices[1].Store.Currency);

        var grape = fruits.First(f => f.Name == "Grape");
        Assert.Equal("Small purple or green fruit", grape.Description);
        Assert.Equal(2.79f, grape.StorePrices![0].Price);
        Assert.Equal("Store 3",   grape.StorePrices[0].Store.Name);
        Assert.Equal(2.49f, grape.StorePrices[1].Price);
        Assert.Equal("Store 7",   grape.StorePrices[1].Store.Name);
        Assert.Equal("999 Elm Rd", grape.StorePrices[1].Store.Address!.Address);
        Assert.Equal("Berlin",    grape.StorePrices[1].Store.Address!.City);
        Assert.Equal("Germany",   grape.StorePrices[1].Store.Address!.Country);
        Assert.Equal("EUR",       grape.StorePrices[1].Store.Currency);

        var pineapple = fruits.First(f => f.Name == "Pineapple");
        Assert.Equal("Large tropical fruit", pineapple.Description);
        Assert.Equal(599.99f, pineapple.StorePrices![0].Price);
        Assert.Equal("Store 4",       pineapple.StorePrices[0].Store.Name);
        Assert.Equal("321 Cherry Ln", pineapple.StorePrices[0].Store.Address!.Address);
        Assert.Equal("Tokyo",         pineapple.StorePrices[0].Store.Address!.City);
        Assert.Equal("Japan",         pineapple.StorePrices[0].Store.Address!.Country);
        Assert.Equal("JPY",           pineapple.StorePrices[0].Store.Currency);
        Assert.Equal(5.49f,  pineapple.StorePrices[1].Price);
        Assert.Equal("Store 6", pineapple.StorePrices[1].Store.Name);
        Assert.Equal(49.99f,  pineapple.StorePrices[2].Price);
        Assert.Equal("Store 8",        pineapple.StorePrices[2].Store.Name);
        Assert.Equal("147 Birch Blvd", pineapple.StorePrices[2].Store.Address!.Address);
        Assert.Equal("Mexico City",    pineapple.StorePrices[2].Store.Address!.City);
        Assert.Equal("Mexico",         pineapple.StorePrices[2].Store.Address!.Country);
        Assert.Equal("MXN",            pineapple.StorePrices[2].Store.Currency);

        var watermelon = fruits.First(f => f.Name == "Watermelon");
        Assert.Equal("Large refreshing summer fruit", watermelon.Description);
        Assert.Equal(6.99f, watermelon.StorePrices![0].Price);
        Assert.Equal("Store 5",    watermelon.StorePrices[0].Store.Name);
        Assert.Equal("555 Maple Dr", watermelon.StorePrices[0].Store.Address!.Address);
        Assert.Equal("Toronto",    watermelon.StorePrices[0].Store.Address!.City);
        Assert.Equal("Canada",     watermelon.StorePrices[0].Store.Address!.Country);
        Assert.Equal("CAD",        watermelon.StorePrices[0].Store.Currency);
        Assert.Equal(4.99f, watermelon.StorePrices[1].Price);
        Assert.Equal("Store 7", watermelon.StorePrices[1].Store.Name);

        var kiwi = fruits.First(f => f.Name == "Kiwi");
        Assert.Equal("Small fuzzy green fruit", kiwi.Description);
        Assert.Equal(1.99f, kiwi.StorePrices![0].Price);
        Assert.Equal("Store 6", kiwi.StorePrices[0].Store.Name);
    }

    [Fact]
    public async Task GetFruitFound()
    {
        var response = await _client.GetAsync("/fruits/Apple", TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var fruit = await response.Content.ReadFromJsonAsync<FruitDto>(TestContext.Current.CancellationToken);
        Assert.NotNull(fruit);
        Assert.True(fruit.Id >= 1);
        Assert.Equal("Apple",        fruit.Name);
        Assert.Equal("Hearty fruit", fruit.Description);
        Assert.Equal(1.29f,     fruit.StorePrices![0].Price);
        Assert.Equal("Store 1",     fruit.StorePrices[0].Store.Name);
        Assert.Equal("123 Main St", fruit.StorePrices[0].Store.Address!.Address);
        Assert.Equal("Anytown",     fruit.StorePrices[0].Store.Address!.City);
        Assert.Equal("USA",         fruit.StorePrices[0].Store.Address!.Country);
        Assert.Equal("USD",         fruit.StorePrices[0].Store.Currency);
        Assert.Equal(2.49f,   fruit.StorePrices[1].Price);
        Assert.Equal("Store 2",    fruit.StorePrices[1].Store.Name);
        Assert.Equal("456 Main St", fruit.StorePrices[1].Store.Address!.Address);
        Assert.Equal("Paris",      fruit.StorePrices[1].Store.Address!.City);
        Assert.Equal("France",     fruit.StorePrices[1].Store.Address!.Country);
        Assert.Equal("EUR",        fruit.StorePrices[1].Store.Currency);
    }

    [Fact]
    public async Task GetFruitNotFound()
    {
        var response = await _client.GetAsync("/fruits/XXXX", TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task AddFruit()
    {
        // Capture the count before adding so the test is order-independent.
        // This mirrors the Quarkus @QuarkusIntegrationTest addFruit() behaviour
        // but without requiring this test to run after the read-only tests.
        var countBefore = (await (await _client.GetAsync("/fruits", TestContext.Current.CancellationToken))
            .Content.ReadFromJsonAsync<List<FruitDto>>(TestContext.Current.CancellationToken))!.Count;

        // Use a unique name so the test is idempotent across repeated runs
        var uniqueName = $"TestLemon_{Guid.NewGuid():N}";
        var postResponse = await _client.PostAsJsonAsync("/fruits", new { name = uniqueName, description = "Acidic fruit" }, TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.OK, postResponse.StatusCode);

        var dto = await postResponse.Content.ReadFromJsonAsync<FruitDto>(TestContext.Current.CancellationToken);
        Assert.NotNull(dto);
        Assert.True(dto.Id >= 1);
        Assert.Equal(uniqueName,    dto.Name);
        Assert.Equal("Acidic fruit", dto.Description);

        var countAfter = (await (await _client.GetAsync("/fruits", TestContext.Current.CancellationToken))
            .Content.ReadFromJsonAsync<List<FruitDto>>(TestContext.Current.CancellationToken))!.Count;
        Assert.Equal(countBefore + 1, countAfter);
    }
}
