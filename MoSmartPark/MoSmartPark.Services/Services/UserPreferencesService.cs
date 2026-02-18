using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Database;
using MoSmartPark.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using MoSmartPark.Model;

namespace MoSmartPark.Services.Services
{
    public class UserPreferencesService : BaseCRUDService<UserPreferencesResponse, UserPreferencesSearchObject, UserPreferences, UserPreferencesUpsertRequest, UserPreferencesUpsertRequest>, IUserPreferencesService
    {
        public UserPreferencesService(MoSmartParkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<UserPreferencesResponse>> GetAsync(UserPreferencesSearchObject search)
        {
            var query = _context.UserPreferences
                .Include(up => up.User)
                .Include(up => up.DefaultParkingZone)
                .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                if (search.PageSize.HasValue)
                    query = query.Take(search.PageSize.Value);
            }

            var list = await query.ToListAsync();
            return new PagedResult<UserPreferencesResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<UserPreferencesResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.UserPreferences
                .Include(up => up.User)
                .Include(up => up.DefaultParkingZone)
                .FirstOrDefaultAsync(up => up.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        public async Task<UserPreferencesResponse> GetByUserIdAsync(int userId)
        {
            var entity = await _context.UserPreferences
                .Include(up => up.User)
                .Include(up => up.DefaultParkingZone)
                .FirstOrDefaultAsync(up => up.UserId == userId);

            if (entity == null)
            {
                // Auto-create default preferences for the user
                entity = new UserPreferences
                {
                    UserId = userId,
                    ThemeMode = "system",
                    NotifyReviews = true,
                    NotifyReservations = true,
                    NotifyCars = true,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.UserPreferences.Add(entity);
                await _context.SaveChangesAsync();

                entity = await _context.UserPreferences
                    .Include(up => up.User)
                    .Include(up => up.DefaultParkingZone)
                    .FirstAsync(up => up.UserId == userId);
            }

            return MapToResponse(entity);
        }

        public async Task<UserPreferencesResponse> UpsertByUserIdAsync(int userId, UserPreferencesUpsertRequest request)
        {
            var entity = await _context.UserPreferences
                .FirstOrDefaultAsync(up => up.UserId == userId);

            if (entity == null)
            {
                entity = new UserPreferences { UserId = userId };
                _context.UserPreferences.Add(entity);
            }

            entity.ThemeMode = request.ThemeMode;
            entity.DefaultParkingZoneId = request.DefaultParkingZoneId;
            entity.NotifyReviews = request.NotifyReviews;
            entity.NotifyReservations = request.NotifyReservations;
            entity.NotifyCars = request.NotifyCars;
            entity.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            entity = await _context.UserPreferences
                .Include(up => up.User)
                .Include(up => up.DefaultParkingZone)
                .FirstAsync(up => up.UserId == userId);

            return MapToResponse(entity);
        }

        protected override IQueryable<UserPreferences> ApplyFilter(IQueryable<UserPreferences> query, UserPreferencesSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(up => up.UserId == search.UserId.Value);

            return query;
        }

        protected override UserPreferencesResponse MapToResponse(UserPreferences entity)
        {
            var response = _mapper.Map<UserPreferencesResponse>(entity);
            response.DefaultParkingZoneName = entity.DefaultParkingZone?.Name;
            return response;
        }

        protected override async Task BeforeInsert(UserPreferences entity, UserPreferencesUpsertRequest request)
        {
            if (!await _context.Users.AnyAsync(u => u.Id == request.UserId))
                throw new InvalidOperationException("User not found.");

            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeUpdate(UserPreferences entity, UserPreferencesUpsertRequest request)
        {
            if (!await _context.Users.AnyAsync(u => u.Id == request.UserId))
                throw new InvalidOperationException("User not found.");

            entity.UpdatedAt = DateTime.UtcNow;
        }
    }
}
