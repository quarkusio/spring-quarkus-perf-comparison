using Dotnet10.Domain;
using Microsoft.EntityFrameworkCore;

namespace Dotnet10.Data;

/// <summary>
/// EF Core DbContext. Configures entity mappings that mirror the JPA annotations in the Quarkus project.
/// </summary>
public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    // Idiomatisches EF-Core-Muster: auto-property mit null!-Initializer.
    // Set<T>() als expression-body-getter ist unüblich und ruft intern
    // ohnehin dieselbe gecachte Methode auf – der Unterschied ist nur stilistisch.
    public DbSet<Fruit> Fruits { get; set; } = null!;
    public DbSet<Store> Stores { get; set; } = null!;
    public DbSet<StoreFruitPrice> StoreFruitPrices { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // ── Fruit ──────────────────────────────────────────────────────────────
        modelBuilder.Entity<Fruit>(e =>
        {
            e.ToTable("fruits");
            e.HasKey(f => f.Id);
            e.Property(f => f.Id).HasColumnName("id").UseHiLo("fruits_seq");
            e.Property(f => f.Name).HasColumnName("name").IsRequired();
            e.HasIndex(f => f.Name).IsUnique();
            e.Property(f => f.Description).HasColumnName("description");
        });

        // ── Store ──────────────────────────────────────────────────────────────
        modelBuilder.Entity<Store>(e =>
        {
            e.ToTable("stores");
            e.HasKey(s => s.Id);
            e.Property(s => s.Id).HasColumnName("id").UseHiLo("stores_seq");
            e.Property(s => s.Name).HasColumnName("name").IsRequired();
            e.HasIndex(s => s.Name).IsUnique();
            e.Property(s => s.Currency).HasColumnName("currency").IsRequired();
            e.OwnsOne(s => s.Address, a =>
            {
                a.Property(x => x.AddressLine).HasColumnName("address").IsRequired();
                a.Property(x => x.City).HasColumnName("city").IsRequired();
                a.Property(x => x.Country).HasColumnName("country").IsRequired();
            });
        });

        // ── StoreFruitPrice ────────────────────────────────────────────────────
        modelBuilder.Entity<StoreFruitPrice>(e =>
        {
            e.ToTable("store_fruit_prices");
            e.HasKey(sp => new { sp.StoreId, sp.FruitId });
            e.Property(sp => sp.StoreId).HasColumnName("store_id");
            e.Property(sp => sp.FruitId).HasColumnName("fruit_id");
            e.Property(sp => sp.Price).HasColumnName("price").HasPrecision(12, 2).IsRequired();
            e.HasOne(sp => sp.Store).WithMany().HasForeignKey(sp => sp.StoreId).IsRequired();
            e.HasOne(sp => sp.Fruit).WithMany(f => f.StorePrices).HasForeignKey(sp => sp.FruitId).IsRequired();
        });
    }
}
