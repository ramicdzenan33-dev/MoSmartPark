using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Model.Requests
{
    public class ParkingZoneCreateWithSpotsRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [Range(1, 26, ErrorMessage = "Rows must be between 1 and 26 (A-Z)")]
        public int Rows { get; set; }

        [Required]
        [Range(1, 100, ErrorMessage = "Columns must be between 1 and 100")]
        public int Columns { get; set; }

        public bool IsActive { get; set; } = true;
    }
}

