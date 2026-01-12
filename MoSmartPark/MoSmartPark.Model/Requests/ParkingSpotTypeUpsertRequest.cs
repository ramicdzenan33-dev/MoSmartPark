using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Model.Requests
{
    public class ParkingSpotTypeUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(200)]
        public string Description { get; set; } = string.Empty;

        [Required]
        [Range(0.01, double.MaxValue, ErrorMessage = "Price multiplier must be greater than 0")]
        public decimal PriceMultiplier { get; set; } = 1.0m;

        [Required]
        public bool IsActive { get; set; } = true;
    }
}

