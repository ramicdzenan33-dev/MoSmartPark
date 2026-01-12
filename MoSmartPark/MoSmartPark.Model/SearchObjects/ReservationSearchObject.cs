using System;

namespace MoSmartPark.Model.SearchObjects
{
    public class ReservationSearchObject : BaseSearchObject
    {
        public int? CarId { get; set; }
        public int? ParkingSpotId { get; set; }
        public int? ReservationTypeId { get; set; }
        public int? UserId { get; set; }
        public DateTime? StartDateFrom { get; set; }
        public DateTime? StartDateTo { get; set; }
        public DateTime? EndDateFrom { get; set; }
        public DateTime? EndDateTo { get; set; }
        public bool IncludePictures { get; set; } = true; // Default to true to include pictures
    }
}
