using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using System.Threading.Tasks;

namespace MoSmartPark.Services.Interfaces
{
    public interface IParkingZoneService : ICRUDService<ParkingZoneResponse, ParkingZoneSearchObject, ParkingZoneUpsertRequest, ParkingZoneUpsertRequest>
    {
        Task<ParkingZoneResponse> CreateWithSpotsAsync(ParkingZoneCreateWithSpotsRequest request);
    }
}

