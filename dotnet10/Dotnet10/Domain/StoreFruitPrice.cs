using System.ComponentModel.DataAnnotations;

namespace Dotnet10.Domain;

/// <summary>
/// Join entity with composite PK (StoreId, FruitId) and a price.
/// Equivalent to @Entity StoreFruitPrice with @EmbeddedId in the Quarkus project.
/// </summary>
public class StoreFruitPrice
{
    public long StoreId { get; set; }
    public long FruitId { get; set; }
    public Store Store { get; set; } = null!;
    public Fruit Fruit { get; set; } = null!;

    [Required]
    [Range(0, double.MaxValue, ErrorMessage = "Price must be >= 0")]
    public decimal Price { get; set; }

    public StoreFruitPrice() { }

    public StoreFruitPrice(Store store, Fruit fruit, decimal price)
    {
        Store = store;
        Fruit = fruit;
        StoreId = store.Id;
        FruitId = fruit.Id;
        Price = price;
    }
}
