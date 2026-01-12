using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoSmartPark.Services.Database
{
    public class Reservation
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CarId { get; set; }

        [Required]
        public int ParkingSpotId { get; set; }

        [Required]
        public int ReservationTypeId { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal FinalPrice { get; set; }

        public string? QrCodeData { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public Car Car { get; set; } = null!;
        public ParkingSpot ParkingSpot { get; set; } = null!;
        public ReservationType ReservationType { get; set; } = null!;
    }
}
