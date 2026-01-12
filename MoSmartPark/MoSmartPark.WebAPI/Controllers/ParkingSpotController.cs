using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    public class ParkingSpotController : BaseCRUDController<ParkingSpotResponse, ParkingSpotSearchObject, ParkingSpotUpsertRequest, ParkingSpotUpsertRequest>
    {
        private readonly IParkingSpotService _parkingSpotService;

        public ParkingSpotController(IParkingSpotService service) : base(service)
        {
            _parkingSpotService = service;
        }

        [AllowAnonymous]
        public override async Task<PagedResult<ParkingSpotResponse>> Get([FromQuery] ParkingSpotSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [AllowAnonymous]
        public override async Task<ParkingSpotResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        /// <summary>
        /// Get recommended parking spot for a user in a specific zone
        /// </summary>
        [HttpGet("recommend/{userId}/{parkingZoneId}")]
        public async Task<ActionResult<ParkingSpotResponse?>> Recommend(
            int userId, 
            int parkingZoneId,
            [FromQuery] int? reservationTypeId = null,
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null)
        {
            var recommendation = await _parkingSpotService.RecommendForUserInZone(userId, parkingZoneId, reservationTypeId, startDate, endDate);
            
            if (recommendation == null)
            {
                return NotFound();
            }

            return recommendation;
        }
    }
}

