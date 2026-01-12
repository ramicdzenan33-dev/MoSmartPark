namespace MoSmartPark.Subscriber.Models
{
    public class ReservationNotification
    {
        public ReservationNotificationDto Reservation { get; set; } = new ReservationNotificationDto();
    }

    public class ReservationNotificationDto
    {
        public string UserEmail { get; set; } = string.Empty;
        public string UserFullName { get; set; } = string.Empty;
        public string CarModel { get; set; } = string.Empty;
        public string CarLicensePlate { get; set; } = string.Empty;
        public string ParkingSpotNumber { get; set; } = string.Empty;
        public string ParkingZoneName { get; set; } = string.Empty;
        public string ReservationTypeName { get; set; } = string.Empty;
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public decimal FinalPrice { get; set; }
    }
}
