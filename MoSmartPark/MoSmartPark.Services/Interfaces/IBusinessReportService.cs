using MoSmartPark.Model.Responses;
using System.Threading.Tasks;

namespace MoSmartPark.Services.Interfaces
{
    public interface IBusinessReportService
    {
        Task<BusinessReportResponse> GetBusinessReportAsync();
    }
}

