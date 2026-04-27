using Dotnet10.Domain;
using Dotnet10.Dto;

namespace Dotnet10.Mapping;

/// <summary>Static mapper for Address ↔ AddressDto. Equivalent to AddressMapper in the Quarkus project.</summary>
public static class AddressMapper
{
    public static AddressDto? Map(Address? address) =>
        address is null ? null : new AddressDto(address.AddressLine, address.City, address.Country);

    public static Address? Map(AddressDto? dto) =>
        dto is null ? null : new Address(dto.Address, dto.City, dto.Country);
}
