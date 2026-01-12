using System;
using System.ComponentModel.DataAnnotations;

namespace MoSmartPark.Model.Requests
{
    public class ReservationUpsertRequest
    {
        [Required]
        public int CarId { get; set; }

        [Required]
        public int ParkingSpotId { get; set; }

        [Required]
        public int ReservationTypeId { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }
    }
}
