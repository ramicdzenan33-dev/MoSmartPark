using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Model.Requests
{
    public class CarUpsertRequest
    {
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
    }
}

