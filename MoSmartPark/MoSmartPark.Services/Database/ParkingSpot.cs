using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Services.Database
{
    public class ParkingSpot
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(20)]
        public string ParkingNumber { get; set; } = string.Empty;

        [Required]
        public int ParkingSpotTypeId { get; set; }

        [Required]
        public int ParkingZoneId { get; set; }

        public bool IsActive { get; set; } = true;

        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        // Navigation properties
        public ParkingSpotType ParkingSpotType { get; set; } = null!;
        public ParkingZone ParkingZone { get; set; } = null!;
    }
}

