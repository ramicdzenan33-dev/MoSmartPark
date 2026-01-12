using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Services.Database
{
    public class ReservationType
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public decimal Price { get; set; }
    }
}
