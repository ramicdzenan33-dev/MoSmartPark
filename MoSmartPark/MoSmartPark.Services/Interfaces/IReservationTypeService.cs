using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;

namespace MoSmartPark.Services.Interfaces
{
    public interface IReservationTypeService : ICRUDService<ReservationTypeResponse, ReservationTypeSearchObject, ReservationTypeUpsertRequest, ReservationTypeUpsertRequest>
    {
    }
}
