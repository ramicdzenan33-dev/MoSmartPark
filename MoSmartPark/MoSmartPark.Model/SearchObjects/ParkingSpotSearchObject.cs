namespace MoSmartPark.Model.SearchObjects
{
    public class ParkingSpotSearchObject : BaseSearchObject
    {
        public string? ParkingNumber { get; set; }
        public int? ParkingSpotTypeId { get; set; }
        public int? ParkingZoneId { get; set; }
        public bool? IsActive { get; set; }
    }
}

