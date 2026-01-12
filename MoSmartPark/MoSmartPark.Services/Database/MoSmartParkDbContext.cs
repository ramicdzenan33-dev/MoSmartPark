using Microsoft.EntityFrameworkCore;

namespace MoSmartPark.Services.Database
{
    public class MoSmartParkDbContext : DbContext
    {
        public MoSmartParkDbContext(DbContextOptions<MoSmartParkDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<UserRole> UserRoles { get; set; }
        public DbSet<Gender> Genders { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<ParkingSpotType> ParkingSpotTypes { get; set; }
        public DbSet<ParkingZone> ParkingZones { get; set; }
        public DbSet<ParkingSpot> ParkingSpots { get; set; }
        public DbSet<Brand> Brands { get; set; }
        public DbSet<Color> Colors { get; set; }
        public DbSet<Car> Cars { get; set; }
        public DbSet<ReservationType> ReservationTypes { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<Review> Reviews { get; set; }
    

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure User entity
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();
               

            // Configure Role entity
            modelBuilder.Entity<Role>()
                .HasIndex(r => r.Name)
                .IsUnique();

            // Configure UserRole join entity
            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.User)
                .WithMany(u => u.UserRoles)
                .HasForeignKey(ur => ur.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.Role)
                .WithMany(r => r.UserRoles)
                .HasForeignKey(ur => ur.RoleId)
                .OnDelete(DeleteBehavior.Cascade);

            // Create a unique constraint on UserId and RoleId
            modelBuilder.Entity<UserRole>()
                .HasIndex(ur => new { ur.UserId, ur.RoleId })
                .IsUnique();

         

            // Configure Gender entity
            modelBuilder.Entity<Gender>()
                .HasIndex(g => g.Name)
                .IsUnique();

            // Configure City entity
            modelBuilder.Entity<City>()
                .HasIndex(c => c.Name)
                .IsUnique();

            // Configure ParkingSpotType entity
            modelBuilder.Entity<ParkingSpotType>()
                .HasIndex(p => p.Name)
                .IsUnique();

            // Configure ParkingZone entity
            modelBuilder.Entity<ParkingZone>()
                .HasIndex(p => p.Name)
                .IsUnique();

            // Configure Brand entity
            modelBuilder.Entity<Brand>()
                .HasIndex(b => b.Name)
                .IsUnique();

            // Configure Color entity
            modelBuilder.Entity<Color>()
                .HasIndex(c => c.Name)
                .IsUnique();

            // Configure ReservationType entity
            modelBuilder.Entity<ReservationType>()
                .HasIndex(r => r.Name)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasOne(u => u.Gender)
                .WithMany()
                .HasForeignKey(u => u.GenderId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<User>()
                .HasOne(u => u.City)
                .WithMany()
                .HasForeignKey(u => u.CityId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure ParkingSpot entity
            modelBuilder.Entity<ParkingSpot>()
                .HasOne(p => p.ParkingSpotType)
                .WithMany()
                .HasForeignKey(p => p.ParkingSpotTypeId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<ParkingSpot>()
                .HasOne(p => p.ParkingZone)
                .WithMany()
                .HasForeignKey(p => p.ParkingZoneId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure Car entity
            modelBuilder.Entity<Car>()
                .HasOne(c => c.Brand)
                .WithMany()
                .HasForeignKey(c => c.BrandId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Car>()
                .HasOne(c => c.Color)
                .WithMany()
                .HasForeignKey(c => c.ColorId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Car>()
                .HasOne(c => c.User)
                .WithMany()
                .HasForeignKey(c => c.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure Reservation entity
            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Car)
                .WithMany()
                .HasForeignKey(r => r.CarId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.ParkingSpot)
                .WithMany()
                .HasForeignKey(r => r.ParkingSpotId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.ReservationType)
                .WithMany()
                .HasForeignKey(r => r.ReservationTypeId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure Review entity
            modelBuilder.Entity<Review>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.Reservation)
                .WithMany()
                .HasForeignKey(r => r.ReservationId)
                .OnDelete(DeleteBehavior.NoAction);

            // Note: ParkingNumber is intentionally NOT unique - multiple spots can have the same number

            // Seed initial data
            modelBuilder.SeedData();
        }
    }
}
