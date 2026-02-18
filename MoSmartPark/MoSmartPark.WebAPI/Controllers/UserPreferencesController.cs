using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace MoSmartPark.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UserPreferencesController : BaseCRUDController<UserPreferencesResponse, UserPreferencesSearchObject, UserPreferencesUpsertRequest, UserPreferencesUpsertRequest>
    {
        private readonly IUserPreferencesService _preferencesService;

        public UserPreferencesController(IUserPreferencesService service) : base(service)
        {
            _preferencesService = service;
        }

        /// <summary>
        /// Gets preferences for a specific user. Creates defaults if none exist.
        /// </summary>
        [HttpGet("user/{userId}")]
        public async Task<UserPreferencesResponse> GetByUserId(int userId)
        {
            return await _preferencesService.GetByUserIdAsync(userId);
        }

        /// <summary>
        /// Creates or updates preferences for a specific user.
        /// </summary>
        [HttpPut("user/{userId}")]
        public async Task<UserPreferencesResponse> UpsertByUserId(int userId, [FromBody] UserPreferencesUpsertRequest request)
        {
            request.UserId = userId;
            return await _preferencesService.UpsertByUserIdAsync(userId, request);
        }
    }
}
