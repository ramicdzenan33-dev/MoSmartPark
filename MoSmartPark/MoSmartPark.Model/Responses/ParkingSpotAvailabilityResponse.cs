namespace MoSmartPark.Model.Responses
{
    public class ParkingSpotAvailabilityResponse
    {
        public int Id { get; set; }
        public string ParkingNumber { get; set; } = string.Empty;
        public string ParkingSpotTypeName { get; set; } = string.Empty;
        public int ParkingZoneId { get; set; }
        public string ParkingZoneName { get; set; } = string.Empty;
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public bool IsAvailable { get; set; }
    }
}
