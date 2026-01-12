using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;

namespace MoSmartPark.Services.Interfaces
{
    public interface ICarService : ICRUDService<CarResponse, CarSearchObject, CarUpsertRequest, CarUpsertRequest>
    {
    }
}

