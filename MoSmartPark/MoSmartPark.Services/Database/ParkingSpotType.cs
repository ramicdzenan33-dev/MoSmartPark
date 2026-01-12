using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Services.Database
{
    public class ParkingSpotType
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(200)]
        public string Description { get; set; } = string.Empty;

        [Required]
        public decimal PriceMultiplier { get; set; } = 1.0m;

        [Required]
        public bool IsActive { get; set; } = true;
    }
}

