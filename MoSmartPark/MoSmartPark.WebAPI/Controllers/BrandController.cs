using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    public class BrandController : BaseCRUDController<BrandResponse, BrandSearchObject, BrandUpsertRequest, BrandUpsertRequest>
    {
        public BrandController(IBrandService service) : base(service)
        {
        }

        [AllowAnonymous]
        public override async Task<PagedResult<BrandResponse>> Get([FromQuery] BrandSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [AllowAnonymous]
        public override async Task<BrandResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }
    }
}

