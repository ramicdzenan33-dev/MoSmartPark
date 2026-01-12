using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Model.Requests
{
    public class ReservationTypeUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [Range(0.01, double.MaxValue, ErrorMessage = "Price must be greater than 0")]
        public decimal Price { get; set; }
    }
}
