using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Model.Requests
{
    public class ConfirmPaymentRequest
    {
        [Required]
        public int ReservationId { get; set; }
    }
}
