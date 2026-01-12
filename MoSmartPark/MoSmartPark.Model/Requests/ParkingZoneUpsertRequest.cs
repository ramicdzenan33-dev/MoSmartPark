using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Model.Requests
{
    public class ParkingZoneUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;
    }
}

