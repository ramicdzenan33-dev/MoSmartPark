using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    /// <summary>
    /// Handles Stripe payment operations for parking reservations.
    /// </summary>
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class StripePaymentController : ControllerBase
    {
        private readonly IStripePaymentService _service;

        public StripePaymentController(IStripePaymentService service)
        {
            _service = service;
        }

        /// <summary>
        /// Creates a Stripe PaymentIntent server-side and returns the client secret for the mobile app.
        /// </summary>
        [HttpPost("create-payment-intent")]
        public async Task<ActionResult<PaymentIntentResponse>> CreatePaymentIntent([FromBody] CreatePaymentIntentRequest request)
        {
            try
            {
                var result = await _service.CreatePaymentIntentAsync(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }

        /// <summary>
        /// Confirms a payment after successful Stripe payment and links it to a reservation.
        /// </summary>
        [HttpPut("{id}/confirm")]
        public async Task<ActionResult<StripePaymentResponse>> ConfirmPayment(int id, [FromBody] ConfirmPaymentRequest request)
        {
            try
            {
                var result = await _service.ConfirmPaymentAsync(id, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }

        /// <summary>
        /// Gets a Stripe payment record by ID.
        /// </summary>
        [HttpGet("{id}")]
        public async Task<ActionResult<StripePaymentResponse>> GetById(int id)
        {
            var result = await _service.GetByIdAsync(id);
            if (result == null)
                return NotFound();

            return Ok(result);
        }
    }
}
