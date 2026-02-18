using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Model.Requests;
using MoSmartPark.Services.Database;

namespace MoSmartPark.Services.Interfaces
{
    public interface INotificationService : ICRUDService<NotificationResponse, NotificationSearchObject, NotificationUpsertRequest, NotificationUpsertRequest>
    {
        Task<int> GetUnreadCountAsync(int userId);
        Task<bool> MarkAsReadAsync(int notificationId);
        Task<bool> MarkAllAsReadAsync(int userId);
        Task CreateNotificationAsync(int userId, string notificationType, string title, string message, string? relatedEntityType = null, int? relatedEntityId = null);
    }
}
