using System.ComponentModel.DataAnnotations;

namespace Dotnet10.Domain;

/// <summary>Fruit entity. Equivalent to @Entity Fruit in the Quarkus project.</summary>
public class Fruit
{
    public long Id { get; set; }

    [Required(ErrorMessage = "Name is mandatory")]
    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public IList<StoreFruitPrice> StorePrices { get; set; } = [];

    public Fruit() { }

    public Fruit(long id, string name, string? description)
    {
        Id = id;
        Name = name;
        Description = description;
    }
}
