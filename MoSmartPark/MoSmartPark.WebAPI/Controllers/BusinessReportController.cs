using MoSmartPark.Model.Responses;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;

namespace MoSmartPark.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class BusinessReportController : ControllerBase
    {
        private readonly IBusinessReportService _service;

        public BusinessReportController(IBusinessReportService service)
        {
            _service = service;
        }

        [HttpGet("")]
        public async Task<BusinessReportResponse> Get()
        {
            return await _service.GetBusinessReportAsync();
        }
    }
}

