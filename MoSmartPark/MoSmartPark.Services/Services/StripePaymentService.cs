using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Services.Database;
using MoSmartPark.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Stripe;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MoSmartPark.Services.Services
{
    public class StripePaymentService : IStripePaymentService
    {
        private readonly MoSmartParkDbContext _context;
        private readonly string _stripeSecretKey;

        public StripePaymentService(MoSmartParkDbContext context, IConfiguration configuration)
        {
            _context = context;
            _stripeSecretKey = configuration["STRIPE:SECRET_KEY"]
                ?? configuration["STRIPE__SECRET_KEY"]
                ?? Environment.GetEnvironmentVariable("STRIPE__SECRET_KEY")
                ?? throw new InvalidOperationException("STRIPE__SECRET_KEY configuration is missing. Please set it in .env file or environment variables.");
        }

        public async Task<PaymentIntentResponse> CreatePaymentIntentAsync(CreatePaymentIntentRequest request)
        {
            StripeConfiguration.ApiKey = _stripeSecretKey;

            // 1. Create Stripe customer
            var customerService = new CustomerService();
            var customer = await customerService.CreateAsync(new CustomerCreateOptions
            {
                Name = request.CustomerName,
                Email = request.CustomerEmail ?? "",
                Metadata = new Dictionary<string, string>
                {
                    { "address", request.BillingAddress ?? "" },
                    { "city", request.BillingCity ?? "" },
                    { "state", request.BillingState ?? "" },
                    { "country", request.BillingCountry ?? "" },
                }
            });

            // 2. Create ephemeral key for the customer
            var ephemeralKeyService = new EphemeralKeyService();
            var ephemeralKey = await ephemeralKeyService.CreateAsync(new EphemeralKeyCreateOptions
            {
                Customer = customer.Id,
            });

            // 3. Create payment intent
            var amountInCents = (long)(request.Amount * 100);
            var paymentIntentService = new PaymentIntentService();
            var paymentIntent = await paymentIntentService.CreateAsync(new PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = request.Currency.ToLower(),
                Customer = customer.Id,
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true,
                },
                Description = "MoSmartPark Parking Reservation",
                Metadata = new Dictionary<string, string>
                {
                    { "customer_name", request.CustomerName },
                    { "billing_address", request.BillingAddress ?? "" },
                    { "billing_city", request.BillingCity ?? "" },
                    { "billing_state", request.BillingState ?? "" },
                    { "billing_country", request.BillingCountry ?? "" },
                }
            });

            // 4. Save payment record to database
            var stripePayment = new Database.StripePayment
            {
                StripePaymentIntentId = paymentIntent.Id,
                StripeCustomerId = customer.Id,
                Amount = request.Amount,
                Currency = request.Currency,
                Status = "pending",
                PaymentMethod = "card",
                CustomerName = request.CustomerName,
                CustomerEmail = request.CustomerEmail,
                BillingAddress = request.BillingAddress,
                BillingCity = request.BillingCity,
                BillingState = request.BillingState,
                BillingCountry = request.BillingCountry,
                BillingZipCode = request.BillingZipCode,
                CreatedAt = DateTime.UtcNow,
            };

            _context.StripePayments.Add(stripePayment);
            await _context.SaveChangesAsync();

            return new PaymentIntentResponse
            {
                StripePaymentId = stripePayment.Id,
                ClientSecret = paymentIntent.ClientSecret,
                EphemeralKey = ephemeralKey.Secret,
                CustomerId = customer.Id,
            };
        }

        public async Task<StripePaymentResponse> ConfirmPaymentAsync(int stripePaymentId, ConfirmPaymentRequest request)
        {
            var payment = await _context.StripePayments.FindAsync(stripePaymentId);
            if (payment == null)
            {
                throw new InvalidOperationException($"Stripe payment with ID {stripePaymentId} not found.");
            }

            // Verify the reservation exists
            var reservation = await _context.Reservations.FindAsync(request.ReservationId);
            if (reservation == null)
            {
                throw new InvalidOperationException($"Reservation with ID {request.ReservationId} not found.");
            }

            payment.ReservationId = request.ReservationId;
            payment.Status = "succeeded";
            payment.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return MapToResponse(payment);
        }

        public async Task<StripePaymentResponse?> GetByIdAsync(int id)
        {
            var payment = await _context.StripePayments
                .Include(sp => sp.Reservation)
                .FirstOrDefaultAsync(sp => sp.Id == id);

            if (payment == null)
                return null;

            return MapToResponse(payment);
        }

        private static StripePaymentResponse MapToResponse(Database.StripePayment entity)
        {
            return new StripePaymentResponse
            {
                Id = entity.Id,
                ReservationId = entity.ReservationId,
                StripePaymentIntentId = entity.StripePaymentIntentId,
                StripeCustomerId = entity.StripeCustomerId,
                Amount = entity.Amount,
                Currency = entity.Currency,
                Status = entity.Status,
                PaymentMethod = entity.PaymentMethod,
                CustomerName = entity.CustomerName,
                CustomerEmail = entity.CustomerEmail,
                BillingAddress = entity.BillingAddress,
                BillingCity = entity.BillingCity,
                BillingState = entity.BillingState,
                BillingCountry = entity.BillingCountry,
                BillingZipCode = entity.BillingZipCode,
                CreatedAt = entity.CreatedAt,
                UpdatedAt = entity.UpdatedAt,
            };
        }
    }
}
