namespace MoSmartPark.Model.Requests
{
    public class UserPreferencesUpsertRequest
    {
        public int UserId { get; set; }
        public string ThemeMode { get; set; } = "system";
        public int? DefaultParkingZoneId { get; set; }
        public bool NotifyReviews { get; set; } = true;
        public bool NotifyReservations { get; set; } = true;
        public bool NotifyCars { get; set; } = true;
    }
}
