using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    public class ParkingSpotTypeController : BaseCRUDController<ParkingSpotTypeResponse, ParkingSpotTypeSearchObject, ParkingSpotTypeUpsertRequest, ParkingSpotTypeUpsertRequest>
    {
        public ParkingSpotTypeController(IParkingSpotTypeService service) : base(service)
        {
        }

        [AllowAnonymous]
        public override async Task<PagedResult<ParkingSpotTypeResponse>> Get([FromQuery] ParkingSpotTypeSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [AllowAnonymous]
        public override async Task<ParkingSpotTypeResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }
    }
}

