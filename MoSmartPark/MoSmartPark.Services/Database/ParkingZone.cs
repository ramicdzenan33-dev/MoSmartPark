using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Services.Database
{
    public class ParkingZone
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;
    }
}

