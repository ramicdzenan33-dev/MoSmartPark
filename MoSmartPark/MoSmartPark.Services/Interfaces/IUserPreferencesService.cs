using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Model.Requests;

namespace MoSmartPark.Services.Interfaces
{
    public interface IUserPreferencesService : ICRUDService<UserPreferencesResponse, UserPreferencesSearchObject, UserPreferencesUpsertRequest, UserPreferencesUpsertRequest>
    {
        Task<UserPreferencesResponse> GetByUserIdAsync(int userId);
        Task<UserPreferencesResponse> UpsertByUserIdAsync(int userId, UserPreferencesUpsertRequest request);
    }
}
