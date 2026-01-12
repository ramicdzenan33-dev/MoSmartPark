using MoSmartPark.Services.Helpers;
using Microsoft.EntityFrameworkCore;
using System;

namespace MoSmartPark.Services.Database
{
    public static class DataSeeder
    {
        private const string DefaultPhoneNumber = "+387 61 123 456";
        
        public static void SeedData(this ModelBuilder modelBuilder)
        {
            // Use a fixed date for all timestamps
            var fixedDate = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);

            // Seed Roles
            modelBuilder.Entity<Role>().HasData(
                   new Role
                   {
                       Id = 1,
                       Name = "Administrator",
                       Description = "Full system access and administrative privileges",
                       CreatedAt = fixedDate,
                       IsActive = true
                   },
                   new Role
                   {
                       Id = 2,
                       Name = "User",
                       Description = "Standard user with limited system access",
                       CreatedAt = fixedDate,
                       IsActive = true
                   }
            );


            const string defaultPassword = "test";

            var desktopSalt = PasswordGenerator.GenerateDeterministicSalt("desktop");
            var desktopHash = PasswordGenerator.GenerateHash(defaultPassword, desktopSalt);

            var userSalt = PasswordGenerator.GenerateDeterministicSalt("user");
            var userHash = PasswordGenerator.GenerateHash(defaultPassword, userSalt);

            var user2Salt = PasswordGenerator.GenerateDeterministicSalt("user2");
            var user2Hash = PasswordGenerator.GenerateHash(defaultPassword, user2Salt);

            var user3Salt = PasswordGenerator.GenerateDeterministicSalt("user3");
            var user3Hash = PasswordGenerator.GenerateHash(defaultPassword, user3Salt);

            // Generate password hashes for 10 additional users
            var user4Salt = PasswordGenerator.GenerateDeterministicSalt("user4");
            var user4Hash = PasswordGenerator.GenerateHash(defaultPassword, user4Salt);
            var user5Salt = PasswordGenerator.GenerateDeterministicSalt("user5");
            var user5Hash = PasswordGenerator.GenerateHash(defaultPassword, user5Salt);
            var user6Salt = PasswordGenerator.GenerateDeterministicSalt("user6");
            var user6Hash = PasswordGenerator.GenerateHash(defaultPassword, user6Salt);
            var user7Salt = PasswordGenerator.GenerateDeterministicSalt("user7");
            var user7Hash = PasswordGenerator.GenerateHash(defaultPassword, user7Salt);
            var user8Salt = PasswordGenerator.GenerateDeterministicSalt("user8");
            var user8Hash = PasswordGenerator.GenerateHash(defaultPassword, user8Salt);
            var user9Salt = PasswordGenerator.GenerateDeterministicSalt("user9");
            var user9Hash = PasswordGenerator.GenerateHash(defaultPassword, user9Salt);
            var user10Salt = PasswordGenerator.GenerateDeterministicSalt("user10");
            var user10Hash = PasswordGenerator.GenerateHash(defaultPassword, user10Salt);
            var user11Salt = PasswordGenerator.GenerateDeterministicSalt("user11");
            var user11Hash = PasswordGenerator.GenerateHash(defaultPassword, user11Salt);
            var user12Salt = PasswordGenerator.GenerateDeterministicSalt("user12");
            var user12Hash = PasswordGenerator.GenerateHash(defaultPassword, user12Salt);
            var user13Salt = PasswordGenerator.GenerateDeterministicSalt("user13");
            var user13Hash = PasswordGenerator.GenerateHash(defaultPassword, user13Salt);
            var user14Salt = PasswordGenerator.GenerateDeterministicSalt("user14");
            var user14Hash = PasswordGenerator.GenerateHash(defaultPassword, user14Salt);



            // Seed Users
            modelBuilder.Entity<User>().HasData(
                new User 
                {
                    Id = 1,
                    FirstName = "Dženan",
                    LastName = "Krečinič",
                    Email = "dzenan.mosmartpark@gmail.com",
                    Username = "desktop",
                    PasswordHash = desktopHash,
                    PasswordSalt = desktopSalt,
                    IsActive = true,
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 1, // Male
                    CityId = 1, // Sarajevo
                    Picture = ImageConversion.ConvertImageToByteArray("Assets", "pic1.png")
                },
                new User 
                { 
                    Id = 2, 
                    FirstName = "Jane", // female 
                    LastName = "Doe",
                    Email = "mosmartparkreciever@gmail.com",
                    Username = "user", 
                    PasswordHash = userHash, 
                    PasswordSalt = userSalt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 1, // Male
                    CityId = 5, // Mostar
                    Picture = ImageConversion.ConvertImageToByteArray("Assets", "pic4.png")
                },
                new User 
                { 
                    Id = 3, 
                    FirstName = "Emily", 
                    LastName = "Smith",
                    Email = "emily.smith@gmail.com",
                    Username = "user2", 
                    PasswordHash = user2Hash, 
                    PasswordSalt = user2Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 2, // Female
                    CityId = 3, // Tuzla
                    Picture = ImageConversion.ConvertImageToByteArray("Assets", "pic2.png")
                },
                new User 
                { 
                    Id = 4, 
                    FirstName = "Michael", 
                    LastName = "Johnson", 
                    Email = "michael.johnson@gmail.com", 
                    Username = "user3", 
                    PasswordHash = user3Hash, 
                    PasswordSalt = user3Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 1, // Male
                    CityId = 1, // Sarajevo
                    Picture = ImageConversion.ConvertImageToByteArray("Assets", "pic3.png")
                },
                new User 
                { 
                    Id = 5, 
                    FirstName = "Sarah", 
                    LastName = "Williams", 
                    Email = "sarah.williams@gmail.com", 
                    Username = "user4", 
                    PasswordHash = user4Hash, 
                    PasswordSalt = user4Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 2, // Female
                    CityId= 3
                },
                new User 
                { 
                    Id = 6, 
                    FirstName = "David", 
                    LastName = "Brown", 
                    Email = "david.brown@gmail.com", 
                    Username = "user5", 
                    PasswordHash = user5Hash, 
                    PasswordSalt = user5Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 1, // Male
                    CityId = 4, // Zenica
                },
                new User 
                { 
                    Id = 7, 
                    FirstName = "Lisa", 
                    LastName = "Anderson", 
                    Email = "lisa.anderson@gmail.com", 
                    Username = "user6", 
                    PasswordHash = user6Hash, 
                    PasswordSalt = user6Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 2, // Female
                    CityId = 6, // Bijeljina
                },
                new User 
                { 
                    Id = 8, 
                    FirstName = "James", 
                    LastName = "Taylor", 
                    Email = "james.taylor@gmail.com", 
                    Username = "user7", 
                    PasswordHash = user7Hash, 
                    PasswordSalt = user7Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 1, // Male
                    CityId = 7, // Prijedor
                },
                new User 
                { 
                    Id = 9, 
                    FirstName = "Maria", 
                    LastName = "Garcia", 
                    Email = "maria.garcia@gmail.com", 
                    Username = "user8", 
                    PasswordHash = user8Hash, 
                    PasswordSalt = user8Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 2, // Female
                    CityId = 8, // Brčko
                },
                new User 
                { 
                    Id = 10, 
                    FirstName = "Robert", 
                    LastName = "Martinez", 
                    Email = "robert.martinez@gmail.com", 
                    Username = "user9", 
                    PasswordHash = user9Hash, 
                    PasswordSalt = user9Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 1, // Male
                    CityId = 9, // Doboj
                },
                new User 
                { 
                    Id = 11, 
                    FirstName = "Jennifer", 
                    LastName = "Lee", 
                    Email = "jennifer.lee@gmail.com", 
                    Username = "user10", 
                    PasswordHash = user10Hash, 
                    PasswordSalt = user10Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 2, // Female
                    CityId = 10, // Zvornik
                },
                new User 
                { 
                    Id = 12, 
                    FirstName = "William", 
                    LastName = "Harris", 
                    Email = "william.harris@gmail.com", 
                    Username = "user11", 
                    PasswordHash = user11Hash, 
                    PasswordSalt = user11Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 1, // Male
                    CityId = 1, // Sarajevo
                },
                new User 
                { 
                    Id = 13, 
                    FirstName = "Patricia", 
                    LastName = "Clark", 
                    Email = "patricia.clark@gmail.com", 
                    Username = "user12", 
                    PasswordHash = user12Hash, 
                    PasswordSalt = user12Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 2, // Female
                    CityId = 3, // Tuzla
                },
                new User 
                { 
                    Id = 14, 
                    FirstName = "Christopher", 
                    LastName = "Lewis", 
                    Email = "christopher.lewis@gmail.com", 
                    Username = "user13", 
                    PasswordHash = user13Hash, 
                    PasswordSalt = user13Salt, 
                    IsActive = true, 
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 1, // Male
                    CityId = 5, // Mostar
                }
            );

            // Seed UserRoles
            modelBuilder.Entity<UserRole>().HasData(
                new UserRole { Id = 1, UserId = 1, RoleId = 1, DateAssigned = fixedDate }, 
                new UserRole { Id = 2, UserId = 2, RoleId = 2, DateAssigned = fixedDate }, 
                new UserRole { Id = 3, UserId = 3, RoleId = 2, DateAssigned = fixedDate }, 
                new UserRole { Id = 4, UserId = 4, RoleId = 2, DateAssigned = fixedDate },
                new UserRole { Id = 5, UserId = 5, RoleId = 2, DateAssigned = fixedDate },
                new UserRole { Id = 6, UserId = 6, RoleId = 2, DateAssigned = fixedDate },
                new UserRole { Id = 7, UserId = 7, RoleId = 2, DateAssigned = fixedDate },
                new UserRole { Id = 8, UserId = 8, RoleId = 2, DateAssigned = fixedDate },
                new UserRole { Id = 9, UserId = 9, RoleId = 2, DateAssigned = fixedDate },
                new UserRole { Id = 10, UserId = 10, RoleId = 2, DateAssigned = fixedDate },
                new UserRole { Id = 11, UserId = 11, RoleId = 2, DateAssigned = fixedDate },
                new UserRole { Id = 12, UserId = 12, RoleId = 2, DateAssigned = fixedDate },
                new UserRole { Id = 13, UserId = 13, RoleId = 2, DateAssigned = fixedDate },
                new UserRole { Id = 14, UserId = 14, RoleId = 2, DateAssigned = fixedDate }
            );

            // Seed Genders
            modelBuilder.Entity<Gender>().HasData(
                new Gender { Id = 1, Name = "Male" },
                new Gender { Id = 2, Name = "Female" }
            );

            // Seed Cities
            modelBuilder.Entity<City>().HasData(
                new City { Id = 1, Name = "Sarajevo" },
                new City { Id = 2, Name = "Banja Luka" },
                new City { Id = 3, Name = "Tuzla" },
                new City { Id = 4, Name = "Zenica" },
                new City { Id = 5, Name = "Mostar" },
                new City { Id = 6, Name = "Bijeljina" },
                new City { Id = 7, Name = "Prijedor" },
                new City { Id = 8, Name = "Brčko" },
                new City { Id = 9, Name = "Doboj" },
                new City { Id = 10, Name = "Zvornik" }
            );

            // Seed ParkingSpotTypes
            modelBuilder.Entity<ParkingSpotType>().HasData(
                new ParkingSpotType 
                { 
                    Id = 1, 
                    Name = "Regular", 
                    Description = "Standard parking spot for regular vehicles",
                    PriceMultiplier = 1.0m
                },
                new ParkingSpotType 
                { 
                    Id = 2, 
                    Name = "Compact", 
                    Description = "For smaller vehicles",
                    PriceMultiplier = 0.8m
                },
                new ParkingSpotType 
                { 
                    Id = 3, 
                    Name = "Large", 
                    Description = "Spacious parking spot for larger vehicles",
                    PriceMultiplier = 1.5m
                },
                new ParkingSpotType 
                { 
                    Id = 4, 
                    Name = "Electric", 
                    Description = "With electric charging stations",
                    PriceMultiplier = 1.3m
                },
                new ParkingSpotType 
                { 
                    Id = 5, 
                    Name = "Disabled", 
                    Description = "Near to entrances",
                    PriceMultiplier = 0.7m
                }
            );

            // Seed ParkingZones
            modelBuilder.Entity<ParkingZone>().HasData(
                new ParkingZone { Id = 1, Name = "North Wing (Zone 1)", IsActive = true },
                new ParkingZone { Id = 2, Name = "South Wing (Zone 2)", IsActive = true }
            );

            // Seed ParkingSpots for North Wing (Zone 1) and South Wing (Zone 2)
            // Each zone has 4 rows (A, B, C, D) x 10 columns (1-10) = 40 spots per zone
            // Layout per zone:
            // Row A: A1 (Disabled corner), A2-A10 (Regular)
            // Row B: B1-B2 (Electric next to each other), B3-B10 (Regular)
            // Row C: C1-C3 (Compact), C4-C7 (Regular), C8-C10 (Large)
            // Row D: D1-D9 (Regular), D10 (Disabled corner)
            var allSpots = new List<ParkingSpot>();
            int spotId = 1;

            // North Wing (Zone 1)
            // Row A
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "A1", ParkingSpotTypeId = 5, ParkingZoneId = 1, IsActive = true }); // Disabled
            for (int i = 2; i <= 10; i++)
            {
                allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = $"A{i}", ParkingSpotTypeId = 1, ParkingZoneId = 1, IsActive = true }); // Regular
            }

            // Row B
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "B1", ParkingSpotTypeId = 4, ParkingZoneId = 1, IsActive = true }); // Electric
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "B2", ParkingSpotTypeId = 4, ParkingZoneId = 1, IsActive = true }); // Electric
            for (int i = 3; i <= 10; i++)
            {
                allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = $"B{i}", ParkingSpotTypeId = 1, ParkingZoneId = 1, IsActive = true }); // Regular
            }

            // Row C
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C1", ParkingSpotTypeId = 2, ParkingZoneId = 1, IsActive = true }); // Compact
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C2", ParkingSpotTypeId = 2, ParkingZoneId = 1, IsActive = true }); // Compact
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C3", ParkingSpotTypeId = 2, ParkingZoneId = 1, IsActive = true }); // Compact
            for (int i = 4; i <= 7; i++)
            {
                allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = $"C{i}", ParkingSpotTypeId = 1, ParkingZoneId = 1, IsActive = true }); // Regular
            }
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C8", ParkingSpotTypeId = 3, ParkingZoneId = 1, IsActive = true }); // Large
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C9", ParkingSpotTypeId = 3, ParkingZoneId = 1, IsActive = true }); // Large
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C10", ParkingSpotTypeId = 3, ParkingZoneId = 1, IsActive = true }); // Large

            // Row D
            for (int i = 1; i <= 9; i++)
            {
                allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = $"D{i}", ParkingSpotTypeId = 1, ParkingZoneId = 1, IsActive = true }); // Regular
            }
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "D10", ParkingSpotTypeId = 5, ParkingZoneId = 1, IsActive = true }); // Disabled

            // South Wing (Zone 2) - same pattern
            // Row A
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "A1", ParkingSpotTypeId = 5, ParkingZoneId = 2, IsActive = true }); // Disabled
            for (int i = 2; i <= 10; i++)
            {
                allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = $"A{i}", ParkingSpotTypeId = 1, ParkingZoneId = 2, IsActive = true }); // Regular
            }

            // Row B
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "B1", ParkingSpotTypeId = 4, ParkingZoneId = 2, IsActive = true }); // Electric
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "B2", ParkingSpotTypeId = 4, ParkingZoneId = 2, IsActive = true }); // Electric
            for (int i = 3; i <= 10; i++)
            {
                allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = $"B{i}", ParkingSpotTypeId = 1, ParkingZoneId = 2, IsActive = true }); // Regular
            }

            // Row C
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C1", ParkingSpotTypeId = 2, ParkingZoneId = 2, IsActive = true }); // Compact
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C2", ParkingSpotTypeId = 2, ParkingZoneId = 2, IsActive = true }); // Compact
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C3", ParkingSpotTypeId = 2, ParkingZoneId = 2, IsActive = true }); // Compact
            for (int i = 4; i <= 7; i++)
            {
                allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = $"C{i}", ParkingSpotTypeId = 1, ParkingZoneId = 2, IsActive = true }); // Regular
            }
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C8", ParkingSpotTypeId = 3, ParkingZoneId = 2, IsActive = true }); // Large
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C9", ParkingSpotTypeId = 3, ParkingZoneId = 2, IsActive = true }); // Large
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "C10", ParkingSpotTypeId = 3, ParkingZoneId = 2, IsActive = true }); // Large

            // Row D
            for (int i = 1; i <= 9; i++)
            {
                allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = $"D{i}", ParkingSpotTypeId = 1, ParkingZoneId = 2, IsActive = true }); // Regular
            }
            allSpots.Add(new ParkingSpot { Id = spotId++, ParkingNumber = "D10", ParkingSpotTypeId = 5, ParkingZoneId = 2, IsActive = true }); // Disabled

            modelBuilder.Entity<ParkingSpot>().HasData(allSpots);

            // Seed Brands
            modelBuilder.Entity<Brand>().HasData(
                new Brand { Id = 1, Name = "Mercedes-Benz", Logo = ImageConversion.ConvertImageToByteArray("Assets", "1.png") },
                new Brand { Id = 2, Name = "BMW", Logo = ImageConversion.ConvertImageToByteArray("Assets", "2.png") },
                new Brand { Id = 3, Name = "Volkswagen", Logo = ImageConversion.ConvertImageToByteArray("Assets", "3.png") },
                new Brand { Id = 4, Name = "Audi", Logo = ImageConversion.ConvertImageToByteArray("Assets", "4.png") },
                new Brand { Id = 5, Name = "Peugeot", Logo = ImageConversion.ConvertImageToByteArray("Assets", "5.png") },
                new Brand { Id = 6, Name = "Renault", Logo = ImageConversion.ConvertImageToByteArray("Assets", "6.png") },
                new Brand { Id = 7, Name = "Honda", Logo = ImageConversion.ConvertImageToByteArray("Assets", "7.png") }
            );

            // Seed Colors (30 most used car colors)
            modelBuilder.Entity<Color>().HasData(
                new Color { Id = 1, Name = "White", HexCode = "#FFFFFF" },
                new Color { Id = 2, Name = "Black", HexCode = "#000000" },
                new Color { Id = 3, Name = "Silver", HexCode = "#C0C0C0" },
                new Color { Id = 4, Name = "Gray", HexCode = "#808080" },
                new Color { Id = 5, Name = "Red", HexCode = "#FF0000" },
                new Color { Id = 6, Name = "Blue", HexCode = "#0000FF" },
                new Color { Id = 7, Name = "Brown", HexCode = "#A52A2A" },
                new Color { Id = 8, Name = "Green", HexCode = "#008000" },
                new Color { Id = 9, Name = "Beige", HexCode = "#F5F5DC" },
                new Color { Id = 10, Name = "Orange", HexCode = "#FFA500" },
                new Color { Id = 11, Name = "Gold", HexCode = "#FFD700" },
                new Color { Id = 12, Name = "Yellow", HexCode = "#FFFF00" },
                new Color { Id = 13, Name = "Purple", HexCode = "#800080" },
                new Color { Id = 14, Name = "Pink", HexCode = "#FFC0CB" },
                new Color { Id = 15, Name = "Navy Blue", HexCode = "#000080" },
                new Color { Id = 16, Name = "Maroon", HexCode = "#800000" },
                new Color { Id = 17, Name = "Burgundy", HexCode = "#800020" },
                new Color { Id = 18, Name = "Teal", HexCode = "#008080" },
                new Color { Id = 19, Name = "Turquoise", HexCode = "#40E0D0" },
                new Color { Id = 20, Name = "Lime Green", HexCode = "#32CD32" },
                new Color { Id = 21, Name = "Olive", HexCode = "#808000" },
                new Color { Id = 22, Name = "Tan", HexCode = "#D2B48C" },
                new Color { Id = 23, Name = "Cream", HexCode = "#FFFDD0" },
                new Color { Id = 24, Name = "Ivory", HexCode = "#FFFFF0" },
                new Color { Id = 25, Name = "Charcoal", HexCode = "#36454F" },
                new Color { Id = 26, Name = "Midnight Blue", HexCode = "#191970" },
                new Color { Id = 27, Name = "Crimson", HexCode = "#DC143C" },
                new Color { Id = 28, Name = "Forest Green", HexCode = "#228B22" },
                new Color { Id = 29, Name = "Champagne", HexCode = "#F7E7CE" },
                new Color { Id = 30, Name = "Pearl White", HexCode = "#F8F6F0" }
            );

            // Seed Cars
            modelBuilder.Entity<Car>().HasData(
                new Car { Id = 1, BrandId = 3, ColorId = 5, UserId = 2, Model = "Golf GTI MK7", LicensePlate = "A23-K-417", YearOfManufacture = 2020, Picture = ImageConversion.ConvertImageToByteArray("Assets", "car1.png") },
                new Car { Id = 2, BrandId = 6, ColorId = 3, UserId = 3, Model = "Clio", LicensePlate = "J45-M-982", YearOfManufacture = 2021, Picture = ImageConversion.ConvertImageToByteArray("Assets", "car2.png") },
                new Car { Id = 3, BrandId = 5, ColorId = 6, UserId = 4, Model = "208", LicensePlate = "T11-E-306", YearOfManufacture = 2022, Picture = ImageConversion.ConvertImageToByteArray("Assets", "car3.png") },
                new Car { Id = 4, BrandId = 1, ColorId = 2, UserId = 5, Model = "C-Class", LicensePlate = "B12-L-789", YearOfManufacture = 2019 },
                new Car { Id = 5, BrandId = 2, ColorId = 1, UserId = 6, Model = "3 Series", LicensePlate = "C34-M-456", YearOfManufacture = 2020 },
                new Car { Id = 6, BrandId = 4, ColorId = 4, UserId = 7, Model = "A4", LicensePlate = "D56-N-123", YearOfManufacture = 2021 },
                new Car { Id = 7, BrandId = 3, ColorId = 3, UserId = 8, Model = "Passat", LicensePlate = "E78-O-234", YearOfManufacture = 2018 },
                new Car { Id = 8, BrandId = 5, ColorId = 5, UserId = 9, Model = "3008", LicensePlate = "F90-P-567", YearOfManufacture = 2022 },
                new Car { Id = 9, BrandId = 6, ColorId = 6, UserId = 10, Model = "Megane", LicensePlate = "G01-Q-890", YearOfManufacture = 2020 },
                new Car { Id = 10, BrandId = 7, ColorId = 1, UserId = 11, Model = "Civic", LicensePlate = "H23-R-345", YearOfManufacture = 2021 },
                new Car { Id = 11, BrandId = 1, ColorId = 3, UserId = 12, Model = "E-Class", LicensePlate = "I45-S-678", YearOfManufacture = 2019},
                new Car { Id = 12, BrandId = 2, ColorId = 2, UserId = 13, Model = "5 Series", LicensePlate = "J67-T-901", YearOfManufacture = 2020 },
                new Car { Id = 13, BrandId = 4, ColorId = 5, UserId = 14, Model = "Q5", LicensePlate = "K89-U-234", YearOfManufacture = 2022 }
            );

            // Seed ReservationTypes
            modelBuilder.Entity<ReservationType>().HasData(
                new ReservationType { Id = 1, Name = "Monthly", Price = 100.00m },
                new ReservationType { Id = 2, Name = "Daily", Price = 10.00m },
                new ReservationType { Id = 3, Name = "Hourly", Price = 1.00m }
            );

            // Seed Reservations
            // User 3 (Car Id 2) - Monthly reservation for electric spot (B1, Id 13) in Zone 1
            // Monthly Price (100) * Electric Multiplier (1.3) = 130.00
            // User 4 (Car Id 3) - Monthly reservation for regular spot (A2, Id 2) in Zone 1
            // Monthly Price (100) * Regular Multiplier (1.0) = 100.00
            var reservationStartDate = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            var reservationEndDate = new DateTime(2026, 2, 1, 0, 0, 0, DateTimeKind.Utc);
            
            // Helper method to generate QR code data (same format as ReservationService)
            string GenerateQrCodeData(int reservationId, int carId, int parkingSpotId, DateTime? startDate, DateTime? endDate)
            {
                var startDateStr = startDate?.ToString("yyyyMMddHHmm") ?? "";
                var endDateStr = endDate?.ToString("yyyyMMddHHmm") ?? "";
                return $"RESERVATION:{reservationId}:{carId}:{parkingSpotId}:{startDateStr}:{endDateStr}";
            }
            
            // Additional reservations for users 5-14 (dates around 25.12.2025 to 1.2.2026)
            var additionalReservations = new List<Reservation>();
            int reservationId = 3;
            
            // User 5 (Car Id 4) - Sarah Williams
            // Reservation 1: Daily reservation for Large spot (C8, Id 28) in Zone 1
            // Daily Price (10.00) * Large Multiplier (1.5) = 15.00
            var res1Start = new DateTime(2025, 12, 25, 8, 0, 0, DateTimeKind.Utc);
            var res1End = new DateTime(2025, 12, 25, 20, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 4,
                ParkingSpotId = 28, // C8 - Large spot in Zone 1
                ReservationTypeId = 2, // Daily
                StartDate = res1Start,
                EndDate = res1End,
                FinalPrice = 15.00m, // 10.00 * 1.5 (Large multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 4, 28, res1Start, res1End),
                CreatedAt = fixedDate
            });
            // Reservation 2: Hourly reservation for Regular spot (A3, Id 3) in Zone 1
            // 4 hours * Hourly Price (1.00) * Regular Multiplier (1.0) = 4.00
            var res2Start = new DateTime(2026, 1, 15, 10, 0, 0, DateTimeKind.Utc);
            var res2End = new DateTime(2026, 1, 15, 14, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 4,
                ParkingSpotId = 3, // A3 - Regular spot in Zone 1
                ReservationTypeId = 3, // Hourly
                StartDate = res2Start,
                EndDate = res2End,
                FinalPrice = 4.00m, // 4 hours * 1.00 * 1.0
                QrCodeData = GenerateQrCodeData(reservationId - 1, 4, 3, res2Start, res2End),
                CreatedAt = fixedDate
            });

            // User 6 (Car Id 5) - David Brown
            // Reservation 1: Monthly reservation for Compact spot (C1, Id 21) in Zone 1
            // Monthly Price (100.00) * Compact Multiplier (0.8) = 80.00
            var res3Start = new DateTime(2025, 12, 26, 0, 0, 0, DateTimeKind.Utc);
            var res3End = new DateTime(2026, 1, 26, 0, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 5,
                ParkingSpotId = 21, // C1 - Compact spot in Zone 1
                ReservationTypeId = 1, // Monthly
                StartDate = res3Start,
                EndDate = res3End,
                FinalPrice = 80.00m, // 100.00 * 0.8 (Compact multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 5, 21, res3Start, res3End),
                CreatedAt = fixedDate
            });
            // Reservation 2: Daily reservation for Electric spot (B1, Id 51) in Zone 2
            // Daily Price (10.00) * Electric Multiplier (1.3) = 13.00
            var res4Start = new DateTime(2026, 1, 20, 0, 0, 0, DateTimeKind.Utc);
            var res4End = new DateTime(2026, 1, 20, 23, 59, 59, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 5,
                ParkingSpotId = 51, // B1 - Electric spot in Zone 2
                ReservationTypeId = 2, // Daily
                StartDate = res4Start,
                EndDate = res4End,
                FinalPrice = 13.00m, // 10.00 * 1.3 (Electric multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 5, 51, res4Start, res4End),
                CreatedAt = fixedDate
            });

            // User 7 (Car Id 6) - Lisa Anderson
            // Reservation 1: Hourly reservation for Disabled spot (A1, Id 41) in Zone 2
            // 6 hours * Hourly Price (1.00) * Disabled Multiplier (0.7) = 4.20
            var res5Start = new DateTime(2025, 12, 28, 9, 0, 0, DateTimeKind.Utc);
            var res5End = new DateTime(2025, 12, 28, 15, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 6,
                ParkingSpotId = 41, // A1 - Disabled spot in Zone 2
                ReservationTypeId = 3, // Hourly
                StartDate = res5Start,
                EndDate = res5End,
                FinalPrice = 4.20m, // 6 hours * 1.00 * 0.7 (Disabled multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 6, 41, res5Start, res5End),
                CreatedAt = fixedDate
            });
            // Reservation 2: Daily reservation for Regular spot (D5, Id 45) in Zone 2
            // Daily Price (10.00) * Regular Multiplier (1.0) = 10.00
            var res6Start = new DateTime(2026, 1, 25, 0, 0, 0, DateTimeKind.Utc);
            var res6End = new DateTime(2026, 1, 25, 23, 59, 59, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 6,
                ParkingSpotId = 45, // D5 - Regular spot in Zone 2
                ReservationTypeId = 2, // Daily
                StartDate = res6Start,
                EndDate = res6End,
                FinalPrice = 10.00m, // 10.00 * 1.0 (Regular multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 6, 45, res6Start, res6End),
                CreatedAt = fixedDate
            });

            // User 8 (Car Id 7) - James Taylor
            // Reservation 1: Monthly reservation for Large spot (C8, Id 68) in Zone 2
            // Monthly Price (100.00) * Large Multiplier (1.5) = 150.00
            var res7Start = new DateTime(2025, 12, 30, 0, 0, 0, DateTimeKind.Utc);
            var res7End = new DateTime(2026, 1, 30, 0, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 7,
                ParkingSpotId = 68, // C8 - Large spot in Zone 2
                ReservationTypeId = 1, // Monthly
                StartDate = res7Start,
                EndDate = res7End,
                FinalPrice = 150.00m, // 100.00 * 1.5 (Large multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 7, 68, res7Start, res7End),
                CreatedAt = fixedDate
            });
            // Reservation 2: Hourly reservation for Electric spot (B2, Id 52) in Zone 2
            // 8 hours * Hourly Price (1.00) * Electric Multiplier (1.3) = 10.40
            var res8Start = new DateTime(2026, 1, 28, 8, 0, 0, DateTimeKind.Utc);
            var res8End = new DateTime(2026, 1, 28, 16, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 7,
                ParkingSpotId = 52, // B2 - Electric spot in Zone 2
                ReservationTypeId = 3, // Hourly
                StartDate = res8Start,
                EndDate = res8End,
                FinalPrice = 10.40m, // 8 hours * 1.00 * 1.3 (Electric multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 7, 52, res8Start, res8End),
                CreatedAt = fixedDate
            });

            // User 9 (Car Id 8) - Maria Garcia
            // Reservation 1: Daily reservation for Compact spot (C2, Id 22) in Zone 1
            // Daily Price (10.00) * Compact Multiplier (0.8) = 8.00
            var res9Start = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            var res9End = new DateTime(2026, 1, 1, 23, 59, 59, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 8,
                ParkingSpotId = 22, // C2 - Compact spot in Zone 1
                ReservationTypeId = 2, // Daily
                StartDate = res9Start,
                EndDate = res9End,
                FinalPrice = 8.00m, // 10.00 * 0.8 (Compact multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 8, 22, res9Start, res9End),
                CreatedAt = fixedDate
            });
            // Reservation 2: Monthly reservation for Regular spot (A4, Id 4) in Zone 1
            // Monthly Price (100.00) * Regular Multiplier (1.0) = 100.00
            var res10Start = new DateTime(2026, 1, 10, 0, 0, 0, DateTimeKind.Utc);
            var res10End = new DateTime(2026, 2, 10, 0, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 8,
                ParkingSpotId = 4, // A4 - Regular spot in Zone 1
                ReservationTypeId = 1, // Monthly
                StartDate = res10Start,
                EndDate = res10End,
                FinalPrice = 100.00m, // 100.00 * 1.0 (Regular multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 8, 4, res10Start, res10End),
                CreatedAt = fixedDate
            });

            // User 10 (Car Id 9) - Robert Martinez
            // Reservation 1: Hourly reservation for Large spot (C9, Id 29) in Zone 1
            // 5 hours * Hourly Price (1.00) * Large Multiplier (1.5) = 7.50
            var res11Start = new DateTime(2025, 12, 27, 11, 0, 0, DateTimeKind.Utc);
            var res11End = new DateTime(2025, 12, 27, 16, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 9,
                ParkingSpotId = 29, // C9 - Large spot in Zone 1
                ReservationTypeId = 3, // Hourly
                StartDate = res11Start,
                EndDate = res11End,
                FinalPrice = 7.50m, // 5 hours * 1.00 * 1.5 (Large multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 9, 29, res11Start, res11End),
                CreatedAt = fixedDate
            });
            // Reservation 2: Daily reservation for Disabled spot (D10, Id 38) in Zone 1
            // Daily Price (10.00) * Disabled Multiplier (0.7) = 7.00
            var res12Start = new DateTime(2026, 1, 22, 0, 0, 0, DateTimeKind.Utc);
            var res12End = new DateTime(2026, 1, 22, 23, 59, 59, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 9,
                ParkingSpotId = 38, // D10 - Disabled spot in Zone 1
                ReservationTypeId = 2, // Daily
                StartDate = res12Start,
                EndDate = res12End,
                FinalPrice = 7.00m, // 10.00 * 0.7 (Disabled multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 9, 38, res12Start, res12End),
                CreatedAt = fixedDate
            });

            // User 11 (Car Id 10) - Jennifer Lee
            // Reservation 1: Monthly reservation for Electric spot (B1, Id 13) in Zone 1
            // Monthly Price (100.00) * Electric Multiplier (1.3) = 130.00
            // Note: This conflicts with existing reservation 1, so we'll use B2 instead
            var res13Start = new DateTime(2025, 12, 29, 0, 0, 0, DateTimeKind.Utc);
            var res13End = new DateTime(2026, 1, 29, 0, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 10,
                ParkingSpotId = 14, // B2 - Electric spot in Zone 1
                ReservationTypeId = 1, // Monthly
                StartDate = res13Start,
                EndDate = res13End,
                FinalPrice = 130.00m, // 100.00 * 1.3 (Electric multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 10, 14, res13Start, res13End),
                CreatedAt = fixedDate
            });
            // Reservation 2: Hourly reservation for Regular spot (A5, Id 5) in Zone 1
            // 3 hours * Hourly Price (1.00) * Regular Multiplier (1.0) = 3.00
            var res14Start = new DateTime(2026, 1, 30, 12, 0, 0, DateTimeKind.Utc);
            var res14End = new DateTime(2026, 1, 30, 15, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 10,
                ParkingSpotId = 5, // A5 - Regular spot in Zone 1
                ReservationTypeId = 3, // Hourly
                StartDate = res14Start,
                EndDate = res14End,
                FinalPrice = 3.00m, // 3 hours * 1.00 * 1.0
                QrCodeData = GenerateQrCodeData(reservationId - 1, 10, 5, res14Start, res14End),
                CreatedAt = fixedDate
            });

            // User 12 (Car Id 11) - William Harris
            // Reservation 1: Daily reservation for Large spot (C10, Id 30) in Zone 1
            // Daily Price (10.00) * Large Multiplier (1.5) = 15.00
            var res15Start = new DateTime(2026, 1, 2, 0, 0, 0, DateTimeKind.Utc);
            var res15End = new DateTime(2026, 1, 2, 23, 59, 59, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 11,
                ParkingSpotId = 30, // C10 - Large spot in Zone 1
                ReservationTypeId = 2, // Daily
                StartDate = res15Start,
                EndDate = res15End,
                FinalPrice = 15.00m, // 10.00 * 1.5 (Large multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 11, 30, res15Start, res15End),
                CreatedAt = fixedDate
            });
            // Reservation 2: Monthly reservation for Compact spot (C3, Id 23) in Zone 1
            // Monthly Price (100.00) * Compact Multiplier (0.8) = 80.00
            var res16Start = new DateTime(2026, 1, 5, 0, 0, 0, DateTimeKind.Utc);
            var res16End = new DateTime(2026, 2, 5, 0, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 11,
                ParkingSpotId = 23, // C3 - Compact spot in Zone 1
                ReservationTypeId = 1, // Monthly
                StartDate = res16Start,
                EndDate = res16End,
                FinalPrice = 80.00m, // 100.00 * 0.8 (Compact multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 11, 23, res16Start, res16End),
                CreatedAt = fixedDate
            });

            // User 13 (Car Id 12) - Patricia Clark
            // Reservation 1: Hourly reservation for Regular spot (A6, Id 6) in Zone 1
            // 7 hours * Hourly Price (1.00) * Regular Multiplier (1.0) = 7.00
            var res17Start = new DateTime(2025, 12, 31, 10, 0, 0, DateTimeKind.Utc);
            var res17End = new DateTime(2025, 12, 31, 17, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 12,
                ParkingSpotId = 6, // A6 - Regular spot in Zone 1
                ReservationTypeId = 3, // Hourly
                StartDate = res17Start,
                EndDate = res17End,
                FinalPrice = 7.00m, // 7 hours * 1.00 * 1.0
                QrCodeData = GenerateQrCodeData(reservationId - 1, 12, 6, res17Start, res17End),
                CreatedAt = fixedDate
            });
            // Reservation 2: Daily reservation for Electric spot (B2, Id 52) in Zone 2
            // Daily Price (10.00) * Electric Multiplier (1.3) = 13.00
            var res18Start = new DateTime(2026, 1, 27, 0, 0, 0, DateTimeKind.Utc);
            var res18End = new DateTime(2026, 1, 27, 23, 59, 59, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 12,
                ParkingSpotId = 52, // B2 - Electric spot in Zone 2
                ReservationTypeId = 2, // Daily
                StartDate = res18Start,
                EndDate = res18End,
                FinalPrice = 13.00m, // 10.00 * 1.3 (Electric multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 12, 52, res18Start, res18End),
                CreatedAt = fixedDate
            });

            // User 14 (Car Id 13) - Christopher Lewis
            // Reservation 1: Monthly reservation for Disabled spot (D10, Id 80) in Zone 2
            // Monthly Price (100.00) * Disabled Multiplier (0.7) = 70.00
            var res19Start = new DateTime(2026, 1, 3, 0, 0, 0, DateTimeKind.Utc);
            var res19End = new DateTime(2026, 2, 3, 0, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 13,
                ParkingSpotId = 80, // D10 - Disabled spot in Zone 2
                ReservationTypeId = 1, // Monthly
                StartDate = res19Start,
                EndDate = res19End,
                FinalPrice = 70.00m, // 100.00 * 0.7 (Disabled multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 13, 80, res19Start, res19End),
                CreatedAt = fixedDate
            });
            // Reservation 2: Hourly reservation for Large spot (C9, Id 69) in Zone 2
            // 6 hours * Hourly Price (1.00) * Large Multiplier (1.5) = 9.00
            var res20Start = new DateTime(2026, 1, 31, 9, 0, 0, DateTimeKind.Utc);
            var res20End = new DateTime(2026, 1, 31, 15, 0, 0, DateTimeKind.Utc);
            additionalReservations.Add(new Reservation 
            { 
                Id = reservationId++, 
                CarId = 13,
                ParkingSpotId = 69, // C9 - Large spot in Zone 2
                ReservationTypeId = 3, // Hourly
                StartDate = res20Start,
                EndDate = res20End,
                FinalPrice = 9.00m, // 6 hours * 1.00 * 1.5 (Large multiplier)
                QrCodeData = GenerateQrCodeData(reservationId - 1, 13, 69, res20Start, res20End),
                CreatedAt = fixedDate
            });
            
            modelBuilder.Entity<Reservation>().HasData(
                new Reservation 
                { 
                    Id = 1, 
                    CarId = 2, // User 3's car (Clio)
                    ParkingSpotId = 13, // B1 - Electric spot in Zone 1
                    ReservationTypeId = 1, // Monthly
                    StartDate = reservationStartDate,
                    EndDate = reservationEndDate,
                    FinalPrice = 130.00m, // 100.00 * 1.3 (Electric multiplier)
                    QrCodeData = GenerateQrCodeData(1, 2, 13, reservationStartDate, reservationEndDate),
                    CreatedAt = fixedDate
                },
                new Reservation 
                { 
                    Id = 2, 
                    CarId = 3, // User 4's car (208)
                    ParkingSpotId = 2, // A2 - Regular spot in Zone 1
                    ReservationTypeId = 1, // Monthly
                    StartDate = reservationStartDate,
                    EndDate = reservationEndDate,
                    FinalPrice = 100.00m, // 100.00 * 1.0 (Regular multiplier)
                    QrCodeData = GenerateQrCodeData(2, 3, 2, reservationStartDate, reservationEndDate),
                    CreatedAt = fixedDate
                }
            );
            
            // Add all additional reservations
            modelBuilder.Entity<Reservation>().HasData(additionalReservations);

            // Seed Reviews
            // User 3 (Emily Smith) - Review for Reservation 1 (her own reservation)
            // User 4 (Michael Johnson) - Review for Reservation 2 (his own reservation)
            modelBuilder.Entity<Review>().HasData(
                new Review 
                { 
                    Id = 1, 
                    UserId = 3, // Emily Smith
                    ReservationId = 1, // Her reservation (electric spot)
                    Rating = 5,
                    Comment = "Excellent parking spot with electric charging! Very convenient and well-maintained.",
                    CreatedAt = fixedDate
                },
                new Review 
                { 
                    Id = 2, 
                    UserId = 4, // Michael Johnson
                    ReservationId = 2, // His reservation (regular spot)
                    Rating = 4,
                    Comment = "Good parking location, easy access. Would recommend.",
                    CreatedAt = fixedDate
                }
            );

        }
    }
} 