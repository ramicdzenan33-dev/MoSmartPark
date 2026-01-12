using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Model.Requests
{
    public class ParkingSpotUpsertRequest
    {
        [Required]
        [MaxLength(20)]
        public string ParkingNumber { get; set; } = string.Empty;

        [Required]
        public int ParkingSpotTypeId { get; set; }

        [Required]
        public int ParkingZoneId { get; set; }

        public bool IsActive { get; set; } = true;
    }
}

