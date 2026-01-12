using MoSmartPark.Services.Database;
using System.Collections.Generic;
using System.Threading.Tasks;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.Requests;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Services;

namespace MoSmartPark.Services.Interfaces
{
    public interface IUserService : IService<UserResponse, UserSearchObject>
    {
        Task<UserResponse?> AuthenticateAsync(UserLoginRequest request);
        Task<UserResponse> CreateAsync(UserUpsertRequest request);
        Task<UserResponse?> UpdateAsync(int id, UserUpsertRequest request);
        Task<bool> DeleteAsync(int id);
    }
}