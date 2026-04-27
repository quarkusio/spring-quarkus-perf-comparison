using Dotnet10.Domain;
using Dotnet10.Dto;

namespace Dotnet10.Mapping;

/// <summary>Static mapper for Store ↔ StoreDto. Equivalent to StoreMapper in the Quarkus project.</summary>
public static class StoreMapper
{
    public static StoreDto? Map(Store? store) =>
        store is null
            ? null
            : new StoreDto(store.Id, store.Name, store.Currency, AddressMapper.Map(store.Address));

    public static Store? Map(StoreDto? dto) =>
        dto is null
            ? null
            : new Store(0, dto.Name, AddressMapper.Map(dto.Address)!, dto.Currency);
}
