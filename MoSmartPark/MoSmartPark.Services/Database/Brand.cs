using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Services.Database
{
    public class Brand
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public byte[]? Logo { get; set; }

        public bool IsActive { get; set; } = true;
    }
}

