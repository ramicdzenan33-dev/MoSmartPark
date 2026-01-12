using System;

namespace MoSmartPark.Model.Responses
{
    public class ReviewResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ReservationId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
        
        // Navigation property details
        public string? UserFullName { get; set; }
        public string? UserEmail { get; set; }
        public string? UserPicture { get; set; }
        
        // Reservation details
        public string? CarBrandName { get; set; }
        public string? CarModel { get; set; }
        public string? CarLicensePlate { get; set; }
        public string? CarPicture { get; set; }
        public string? ParkingSpotNumber { get; set; }
        public string? ReservationTypeName { get; set; }
        public DateTime? ReservationStartDate { get; set; }
        public DateTime? ReservationEndDate { get; set; }
        public decimal? ReservationFinalPrice { get; set; }
    }
}
