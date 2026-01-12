using MoSmartPark.Model.Responses;
using MoSmartPark.Services.Database;
using MoSmartPark.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MoSmartPark.Services.Services
{
    public class BusinessReportService : IBusinessReportService
    {
        private readonly MoSmartParkDbContext _context;

        public BusinessReportService(MoSmartParkDbContext context)
        {
            _context = context;
        }

        public async Task<BusinessReportResponse> GetBusinessReportAsync()
        {
            var report = new BusinessReportResponse();

            // Overall Statistics
            var totalRevenue = await _context.Reservations
                .SumAsync(r => r.FinalPrice);
            report.TotalRevenue = totalRevenue;

            var totalReservations = await _context.Reservations.CountAsync();
            report.TotalReservations = totalReservations;

            var activeUsers = await _context.Users
                .Where(u => u.IsActive)
                .CountAsync();
            report.ActiveUsers = activeUsers;

            var totalParkingSpots = await _context.ParkingSpots.CountAsync();
            report.TotalParkingSpots = totalParkingSpots;

            var activeParkingSpots = await _context.ParkingSpots
                .Where(ps => ps.IsActive)
                .CountAsync();
            report.ActiveParkingSpots = activeParkingSpots;

            report.AverageReservationPrice = totalReservations > 0 
                ? totalRevenue / totalReservations 
                : 0;

            // Revenue by Reservation Type
            var revenueByType = await _context.Reservations
                .Include(r => r.ReservationType)
                .GroupBy(r => r.ReservationType)
                .Select(g => new RevenueByType
                {
                    ReservationTypeName = g.Key.Name,
                    Revenue = g.Sum(r => r.FinalPrice),
                    Count = g.Count()
                })
                .OrderByDescending(x => x.Revenue)
                .ToListAsync();
            report.RevenueByReservationType = revenueByType;

            // Reservations by Type
            var reservationsByType = await _context.Reservations
                .Include(r => r.ReservationType)
                .GroupBy(r => r.ReservationType)
                .Select(g => new ReservationCountByType
                {
                    ReservationTypeName = g.Key.Name,
                    Count = g.Count()
                })
                .OrderByDescending(x => x.Count)
                .ToListAsync();
            report.ReservationsByType = reservationsByType;

            // Revenue by Zone
            var revenueByZone = await _context.Reservations
                .Include(r => r.ParkingSpot)
                    .ThenInclude(ps => ps.ParkingZone)
                .GroupBy(r => r.ParkingSpot.ParkingZone)
                .Select(g => new RevenueByZone
                {
                    ZoneName = g.Key.Name,
                    Revenue = g.Sum(r => r.FinalPrice),
                    Count = g.Count()
                })
                .OrderByDescending(x => x.Revenue)
                .ToListAsync();
            report.RevenueByZone = revenueByZone;

            // Reservations by Zone
            var reservationsByZone = await _context.Reservations
                .Include(r => r.ParkingSpot)
                    .ThenInclude(ps => ps.ParkingZone)
                .GroupBy(r => r.ParkingSpot.ParkingZone)
                .Select(g => new ReservationCountByZone
                {
                    ZoneName = g.Key.Name,
                    Count = g.Count()
                })
                .OrderByDescending(x => x.Count)
                .ToListAsync();
            report.ReservationsByZone = reservationsByZone;

            // Most Popular Zones (by reservation count)
            var popularZones = await _context.Reservations
                .Include(r => r.ParkingSpot)
                    .ThenInclude(ps => ps.ParkingZone)
                .GroupBy(r => r.ParkingSpot.ParkingZone)
                .Select(g => new PopularZone
                {
                    ZoneName = g.Key.Name,
                    ReservationCount = g.Count(),
                    TotalRevenue = g.Sum(r => r.FinalPrice)
                })
                .OrderByDescending(x => x.ReservationCount)
                .Take(5)
                .ToListAsync();
            report.MostPopularZones = popularZones;

            // Recent Reservations (last 10)
            var recentReservations = await _context.Reservations
                .Include(r => r.ParkingSpot)
                    .ThenInclude(ps => ps.ParkingZone)
                .Include(r => r.ReservationType)
                .Include(r => r.Car)
                    .ThenInclude(c => c.User)
                .OrderByDescending(r => r.CreatedAt)
                .Take(10)
                .Select(r => new RecentReservation
                {
                    Id = r.Id,
                    ParkingSpotNumber = r.ParkingSpot.ParkingNumber,
                    ZoneName = r.ParkingSpot.ParkingZone.Name,
                    ReservationTypeName = r.ReservationType.Name,
                    UserFullName = $"{r.Car.User.FirstName} {r.Car.User.LastName}".Trim(),
                    FinalPrice = r.FinalPrice,
                    StartDate = r.StartDate,
                    EndDate = r.EndDate,
                    CreatedAt = r.CreatedAt
                })
                .ToListAsync();
            report.RecentReservations = recentReservations;

            return report;
        }
    }
}

