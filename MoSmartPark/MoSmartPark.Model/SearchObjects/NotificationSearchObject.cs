namespace MoSmartPark.Model.SearchObjects
{
    public class NotificationSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public bool? IsRead { get; set; }
        public string? NotificationType { get; set; }
    }
}
