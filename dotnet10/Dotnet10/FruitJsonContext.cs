using System.Text.Json.Serialization;
using Dotnet10.Dto;

namespace Dotnet10;

/// <summary>
/// Source-generated JSON serializer context for all DTO types.
///
/// /// Equivalent to:
///   quarkus.rest.jackson.optimization.enable-reflection-free-serializers: true
/// </summary>
[JsonSerializable(typeof(FruitDto))]
[JsonSerializable(typeof(List<FruitDto>))]
[JsonSerializable(typeof(StoreFruitPriceDto))]
[JsonSerializable(typeof(List<StoreFruitPriceDto>))]
[JsonSerializable(typeof(StoreDto))]
[JsonSerializable(typeof(AddressDto))]
[JsonSourceGenerationOptions(
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    GenerationMode = JsonSourceGenerationMode.Default)]
public partial class FruitJsonContext : JsonSerializerContext;
