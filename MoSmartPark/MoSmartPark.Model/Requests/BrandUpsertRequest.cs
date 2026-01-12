using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Model.Requests
{
    public class BrandUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public byte[]? Logo { get; set; }

        public bool IsActive { get; set; } = true;
    }
}

