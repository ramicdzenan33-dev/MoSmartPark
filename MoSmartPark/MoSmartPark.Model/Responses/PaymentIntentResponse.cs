namespace MoSmartPark.Model.Responses
{
    public class PaymentIntentResponse
    {
        public int StripePaymentId { get; set; }
        public string ClientSecret { get; set; } = string.Empty;
        public string EphemeralKey { get; set; } = string.Empty;
        public string CustomerId { get; set; } = string.Empty;
    }
}
