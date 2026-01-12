using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Database;
using MoSmartPark.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MoSmartPark.Services.Services
{
    public class ParkingZoneService : BaseCRUDService<ParkingZoneResponse, ParkingZoneSearchObject, ParkingZone, ParkingZoneUpsertRequest, ParkingZoneUpsertRequest>, IParkingZoneService
    {
        public ParkingZoneService(MoSmartParkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<ParkingZone> ApplyFilter(IQueryable<ParkingZone> query, ParkingZoneSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(x => x.IsActive == search.IsActive.Value);
            }

            return query;
        }

        protected override async Task BeforeInsert(ParkingZone entity, ParkingZoneUpsertRequest request)
        {
            if (await _context.ParkingZones.AnyAsync(p => p.Name == request.Name))
            {
                throw new InvalidOperationException("A parking zone with this name already exists.");
            }
        }

        protected override async Task BeforeUpdate(ParkingZone entity, ParkingZoneUpsertRequest request)
        {
            if (await _context.ParkingZones.AnyAsync(p => p.Name == request.Name && p.Id != entity.Id))
            {
                throw new InvalidOperationException("A parking zone with this name already exists.");
            }
        }

        public async Task<ParkingZoneResponse> CreateWithSpotsAsync(ParkingZoneCreateWithSpotsRequest request)
        {
            // Validate zone name doesn't exist
            if (await _context.ParkingZones.AnyAsync(p => p.Name == request.Name))
            {
                throw new InvalidOperationException("A parking zone with this name already exists.");
            }

            // Create the zone
            var zone = new ParkingZone
            {
                Name = request.Name,
                IsActive = request.IsActive
            };

            _context.ParkingZones.Add(zone);
            await _context.SaveChangesAsync(); // Save to get the zone ID

            // Generate parking spots
            // Regular parking spot type ID is 1 (from seeder)
            const int regularSpotTypeId = 1;
            var spots = new List<ParkingSpot>();
            int spotNumber = 1;

            // Generate row letters (A, B, C, ..., Z)
            for (int row = 0; row < request.Rows; row++)
            {
                char rowLetter = (char)('A' + row);
                
                // Generate columns (1, 2, 3, ..., Columns)
                for (int col = 1; col <= request.Columns; col++)
                {
                    spots.Add(new ParkingSpot
                    {
                        ParkingNumber = $"{rowLetter}{col}",
                        ParkingSpotTypeId = regularSpotTypeId,
                        ParkingZoneId = zone.Id,
                        IsActive = true
                    });
                }
            }

            _context.ParkingSpots.AddRange(spots);
            await _context.SaveChangesAsync();

            return _mapper.Map<ParkingZoneResponse>(zone);
        }
    }
}

