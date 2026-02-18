using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Services.Database
{
    public class UserPreferences
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        [MaxLength(20)]
        public string ThemeMode { get; set; } = "system";

        public int? DefaultParkingZoneId { get; set; }

        public bool NotifyReviews { get; set; } = true;

        public bool NotifyReservations { get; set; } = true;

        public bool NotifyCars { get; set; } = true;

        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public User User { get; set; } = null!;
        public ParkingZone? DefaultParkingZone { get; set; }
    }
}
