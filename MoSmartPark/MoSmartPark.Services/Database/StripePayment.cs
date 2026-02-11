using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoSmartPark.Services.Database
{
    public class StripePayment
    {
        [Key]
        public int Id { get; set; }

        public int? ReservationId { get; set; }

        [Required]
        [MaxLength(255)]
        public string StripePaymentIntentId { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? StripeCustomerId { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        [Required]
        [MaxLength(10)]
        public string Currency { get; set; } = "USD";

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = "pending";

        [MaxLength(50)]
        public string? PaymentMethod { get; set; }

        [MaxLength(255)]
        public string? CustomerName { get; set; }

        [MaxLength(255)] 
        public string? CustomerEmail { get; set; }

        [MaxLength(500)]
        public string? BillingAddress { get; set; }

        [MaxLength(100)]
        public string? BillingCity { get; set; }

        [MaxLength(100)]
        public string? BillingState { get; set; }

        [MaxLength(100)]
        public string? BillingCountry { get; set; }

        [MaxLength(20)]
        public string? BillingZipCode { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // Navigation property
        public Reservation? Reservation { get; set; }
    }
}
