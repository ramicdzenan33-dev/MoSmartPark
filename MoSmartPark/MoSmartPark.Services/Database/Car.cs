using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Services.Database
{
    public class Car
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int BrandId { get; set; }

        [Required]
        public int ColorId { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        [MaxLength(100)]
        public string Model { get; set; } = string.Empty;

        [Required]
        [MaxLength(20)]
        public string LicensePlate { get; set; } = string.Empty;

        [Required]
        [Range(1900, 2100, ErrorMessage = "Year of manufacture must be between 1900 and 2100")]
        public int YearOfManufacture { get; set; }

        public byte[]? Picture { get; set; }

        public bool IsActive { get; set; } = true;

        // Navigation properties
        public Brand Brand { get; set; } = null!;
        public Color Color { get; set; } = null!;
        public User User { get; set; } = null!;
    }
}

