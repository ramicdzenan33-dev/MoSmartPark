using System;

namespace MoSmartPark.Model.Responses
{
    public class NotificationResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string NotificationType { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string? RelatedEntityType { get; set; }
        public int? RelatedEntityId { get; set; }
        public bool IsRead { get; set; }
        public bool IsSent { get; set; }
        public DateTime? SentAt { get; set; }
        public DateTime CreatedAt { get; set; }
        
        // Navigation properties
        public string? UserName { get; set; }
    }
}
