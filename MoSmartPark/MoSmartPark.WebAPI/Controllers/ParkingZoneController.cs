using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    public class ParkingZoneController : BaseCRUDController<ParkingZoneResponse, ParkingZoneSearchObject, ParkingZoneUpsertRequest, ParkingZoneUpsertRequest>
    {
        private readonly IParkingZoneService _parkingZoneService;

        public ParkingZoneController(IParkingZoneService service) : base(service)
        {
            _parkingZoneService = service;
        }

        [AllowAnonymous]
        public override async Task<PagedResult<ParkingZoneResponse>> Get([FromQuery] ParkingZoneSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [AllowAnonymous]
        public override async Task<ParkingZoneResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpPost("create-with-spots")]
        [AllowAnonymous]
        public async Task<ParkingZoneResponse> CreateWithSpots([FromBody] ParkingZoneCreateWithSpotsRequest request)
        {
            return await _parkingZoneService.CreateWithSpotsAsync(request);
        }
    }
}

