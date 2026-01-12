using System;

namespace MoSmartPark.Model.Responses
{
    public class ReservationResponse
    {
        public int Id { get; set; }
        public int CarId { get; set; }
        public int ParkingSpotId { get; set; }
        public int ReservationTypeId { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public decimal FinalPrice { get; set; }
        public DateTime CreatedAt { get; set; }
        
        // Navigation property details
        public string? CarModel { get; set; }
        public string? CarBrandName { get; set; }
        public string? CarLicensePlate { get; set; }
        public string? CarColorName { get; set; }
        public string? CarColorHexCode { get; set; }
        public string? CarPicture { get; set; }
        public string? ParkingSpotNumber { get; set; }
        public string? ParkingSpotTypeName { get; set; }
        public string? ReservationTypeName { get; set; }
        public string? UserFullName { get; set; }
        public byte[]? UserPicture { get; set; }
        public string? QrCodeData { get; set; }
    }
}
