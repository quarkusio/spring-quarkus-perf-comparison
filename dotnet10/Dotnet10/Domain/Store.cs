using System.ComponentModel.DataAnnotations;

namespace Dotnet10.Domain;

/// <summary>Store entity. Equivalent to @Entity @Cacheable Store in the Quarkus project.</summary>
public class Store
{
    public long Id { get; set; }

    [Required(ErrorMessage = "Name is mandatory")]
    public string Name { get; set; } = null!;

    [Required(ErrorMessage = "Currency is mandatory")]
    public string Currency { get; set; } = null!;

    public Address Address { get; set; } = null!;

    public Store() { }

    public Store(long id, string name, Address address, string currency)
    {
        Id = id;
        Name = name;
        Address = address;
        Currency = currency;
    }
}
