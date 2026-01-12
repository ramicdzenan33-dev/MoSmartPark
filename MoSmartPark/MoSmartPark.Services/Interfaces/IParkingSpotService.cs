using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;

namespace MoSmartPark.Services.Interfaces
{
    public interface IParkingSpotService : ICRUDService<ParkingSpotResponse, ParkingSpotSearchObject, ParkingSpotUpsertRequest, ParkingSpotUpsertRequest>
    {
        Task<ParkingSpotResponse?> RecommendForUserInZone(int userId, int parkingZoneId, int? reservationTypeId = null, DateTime? startDate = null, DateTime? endDate = null);
    }
}

