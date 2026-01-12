using MoSmartPark.Services.Database;
using System.Collections.Generic;
using System.Threading.Tasks;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.Requests;
using MoSmartPark.Model.SearchObjects;

namespace MoSmartPark.Services.Interfaces
{
    public interface IService<T, TSearch> where T : class where TSearch : BaseSearchObject
    {
        Task<PagedResult<T>> GetAsync(TSearch search);
        Task<T?> GetByIdAsync(int id);
    }
}