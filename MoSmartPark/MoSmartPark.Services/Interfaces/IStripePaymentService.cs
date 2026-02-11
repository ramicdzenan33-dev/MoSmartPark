using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using System.Threading.Tasks;

namespace MoSmartPark.Services.Interfaces
{
    public interface IStripePaymentService
    {
        Task<PaymentIntentResponse> CreatePaymentIntentAsync(CreatePaymentIntentRequest request);
        Task<StripePaymentResponse> ConfirmPaymentAsync(int stripePaymentId, ConfirmPaymentRequest request);
        Task<StripePaymentResponse?> GetByIdAsync(int id);
    }
}
