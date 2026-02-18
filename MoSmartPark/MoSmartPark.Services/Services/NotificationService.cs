using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Database;
using MoSmartPark.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;
using MoSmartPark.Model;

namespace MoSmartPark.Services.Services
{
    public class NotificationService : BaseCRUDService<NotificationResponse, NotificationSearchObject, Notification, NotificationUpsertRequest, NotificationUpsertRequest>, INotificationService
    {
        public NotificationService(MoSmartParkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<NotificationResponse>> GetAsync(NotificationSearchObject search)
        {
            var query = _context.Notifications
                .Include(n => n.User)
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
                {
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                }
                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }

            var list = await query.ToListAsync();
            var result = new PagedResult<NotificationResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
            return result;
        }

        public override async Task<NotificationResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Notifications
                .Include(n => n.User)
                .FirstOrDefaultAsync(n => n.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        protected override IQueryable<Notification> ApplyFilter(IQueryable<Notification> query, NotificationSearchObject search)
        {
            if (search.UserId.HasValue)
            {
                query = query.Where(n => n.UserId == search.UserId.Value);
            }

            if (search.IsRead.HasValue)
            {
                query = query.Where(n => n.IsRead == search.IsRead.Value);
            }

            if (!string.IsNullOrEmpty(search.NotificationType))
            {
                query = query.Where(n => n.NotificationType == search.NotificationType);
            }

            // Order by most recent first
            query = query.OrderByDescending(n => n.CreatedAt);

            return query;
        }

        protected override NotificationResponse MapToResponse(Notification entity)
        {
            var response = _mapper.Map<NotificationResponse>(entity);
            
            if (entity.User != null)
            {
                response.UserName = $"{entity.User.FirstName} {entity.User.LastName}";
            }

            return response;
        }

        protected override async Task BeforeInsert(Notification entity, NotificationUpsertRequest request)
        {
            // Validate that user exists
            if (!await _context.Users.AnyAsync(u => u.Id == request.UserId))
            {
                throw new InvalidOperationException("User not found.");
            }

            entity.CreatedAt = DateTime.Now;
            entity.SentAt = DateTime.Now;
            entity.IsSent = true;
        }

        protected override async Task BeforeUpdate(Notification entity, NotificationUpsertRequest request)
        {
            // Validate that user exists
            if (!await _context.Users.AnyAsync(u => u.Id == request.UserId))
            {
                throw new InvalidOperationException("User not found.");
            }
        }

        public async Task<int> GetUnreadCountAsync(int userId)
        {
            return await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .CountAsync();
        }

        public async Task<bool> MarkAsReadAsync(int notificationId)
        {
            var notification = await _context.Notifications.FindAsync(notificationId);
            if (notification == null)
                return false;

            notification.IsRead = true;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> MarkAllAsReadAsync(int userId)
        {
            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();

            foreach (var notification in notifications)
            {
                notification.IsRead = true;
            }

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task CreateNotificationAsync(int userId, string notificationType, string title, string message, string? relatedEntityType = null, int? relatedEntityId = null)
        {
            var notification = new Notification
            {
                UserId = userId,
                NotificationType = notificationType,
                Title = title,
                Message = message,
                RelatedEntityType = relatedEntityType,
                RelatedEntityId = relatedEntityId,
                IsRead = false,
                IsSent = true,
                CreatedAt = DateTime.Now,
                SentAt = DateTime.Now
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();
        }
    }
}
