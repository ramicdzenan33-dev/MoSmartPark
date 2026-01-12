using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    public class ReservationTypeController : BaseCRUDController<ReservationTypeResponse, ReservationTypeSearchObject, ReservationTypeUpsertRequest, ReservationTypeUpsertRequest>
    {
        public ReservationTypeController(IReservationTypeService service) : base(service)
        {
        }

        [AllowAnonymous]
        public override async Task<PagedResult<ReservationTypeResponse>> Get([FromQuery] ReservationTypeSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [AllowAnonymous]
        public override async Task<ReservationTypeResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }
    }
}
