using System;

namespace MoSmartPark.Model.Responses
{
    public class UserPreferencesResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string ThemeMode { get; set; } = "system";
        public int? DefaultParkingZoneId { get; set; }
        public string? DefaultParkingZoneName { get; set; }
        public bool NotifyReviews { get; set; }
        public bool NotifyReservations { get; set; }
        public bool NotifyCars { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
