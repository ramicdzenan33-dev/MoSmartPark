namespace MoSmartPark.Model.Responses
{
    public class ParkingSpotResponse
    {
        public int Id { get; set; }
        public string ParkingNumber { get; set; } = string.Empty;
        public int ParkingSpotTypeId { get; set; }
        public string ParkingSpotTypeName { get; set; } = string.Empty;
        public int ParkingZoneId { get; set; }
        public string ParkingZoneName { get; set; } = string.Empty;
        public bool IsActive { get; set; }
    }
}

