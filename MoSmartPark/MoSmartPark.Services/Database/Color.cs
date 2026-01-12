using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Services.Database
{
    public class Color
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(7)]
        [RegularExpression(@"^#[0-9A-Fa-f]{6}$", ErrorMessage = "HexCode must be in format #RRGGBB")]
        public string HexCode { get; set; } = string.Empty;
    }
}

