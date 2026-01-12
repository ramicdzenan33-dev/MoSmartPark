using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    public class ColorController : BaseCRUDController<ColorResponse, ColorSearchObject, ColorUpsertRequest, ColorUpsertRequest>
    {
        public ColorController(IColorService service) : base(service)
        {
        }

        [AllowAnonymous]
        public override async Task<PagedResult<ColorResponse>> Get([FromQuery] ColorSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [AllowAnonymous]
        public override async Task<ColorResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }
    }
}

