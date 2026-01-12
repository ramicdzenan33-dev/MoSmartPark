using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Model.Requests
{
    public class GenderUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;
    }
} 