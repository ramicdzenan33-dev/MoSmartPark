using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Model.Requests
{
    public class ColorUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(7)]
        [RegularExpression(@"^#[0-9A-Fa-f]{6}$", ErrorMessage = "HexCode must be in format #RRGGBB")]
        public string HexCode { get; set; } = string.Empty;
    }
}

