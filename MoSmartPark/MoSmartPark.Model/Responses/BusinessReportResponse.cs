using System;
using System.Collections.Generic;

namespace MoSmartPark.Model.Responses
{
    public class BusinessReportResponse
    {
        // Overall Statistics
        public decimal TotalRevenue { get; set; }
        public int TotalReservations { get; set; }
        public int ActiveUsers { get; set; }
        public int TotalParkingSpots { get; set; }
        public int ActiveParkingSpots { get; set; }
        public decimal AverageReservationPrice { get; set; }
        
        // Revenue by Reservation Type
        public List<RevenueByType> RevenueByReservationType { get; set; } = new List<RevenueByType>();
        
        // Reservations by Type
        public List<ReservationCountByType> ReservationsByType { get; set; } = new List<ReservationCountByType>();
        
        // Revenue by Zone
        public List<RevenueByZone> RevenueByZone { get; set; } = new List<RevenueByZone>();
        
        // Reservations by Zone
        public List<ReservationCountByZone> ReservationsByZone { get; set; } = new List<ReservationCountByZone>();
        
        // Most Popular Zones
        public List<PopularZone> MostPopularZones { get; set; } = new List<PopularZone>();
        
        // Recent Reservations (last 10)
        public List<RecentReservation> RecentReservations { get; set; } = new List<RecentReservation>();
    }
    
    public class RevenueByType
    {
        public string ReservationTypeName { get; set; } = string.Empty;
        public decimal Revenue { get; set; }
        public int Count { get; set; }
    }
    
    public class ReservationCountByType
    {
        public string ReservationTypeName { get; set; } = string.Empty;
        public int Count { get; set; }
    }
    
    public class RevenueByZone
    {
        public string ZoneName { get; set; } = string.Empty;
        public decimal Revenue { get; set; }
        public int Count { get; set; }
    }
    
    public class ReservationCountByZone
    {
        public string ZoneName { get; set; } = string.Empty;
        public int Count { get; set; }
    }
    
    public class PopularZone
    {
        public string ZoneName { get; set; } = string.Empty;
        public int ReservationCount { get; set; }
        public decimal TotalRevenue { get; set; }
    }
    
    public class RecentReservation
    {
        public int Id { get; set; }
        public string ParkingSpotNumber { get; set; } = string.Empty;
        public string ZoneName { get; set; } = string.Empty;
        public string ReservationTypeName { get; set; } = string.Empty;
        public string UserFullName { get; set; } = string.Empty;
        public decimal FinalPrice { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

