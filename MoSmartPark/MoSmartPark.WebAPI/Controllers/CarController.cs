using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    public class CarController : BaseCRUDController<CarResponse, CarSearchObject, CarUpsertRequest, CarUpsertRequest>
    {
        public CarController(ICarService service) : base(service)
        {
        }

        [AllowAnonymous]
        public override async Task<PagedResult<CarResponse>> Get([FromQuery] CarSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [AllowAnonymous]
        public override async Task<CarResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }
    }
}

