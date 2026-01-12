using MoSmartPark.Model.Requests;
using MoSmartPark.Model.Responses;
using MoSmartPark.Model.SearchObjects;
using MoSmartPark.Services.Database;
using MoSmartPark.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MoSmartPark.Services.Services
{
    public class ParkingSpotTypeService : BaseCRUDService<ParkingSpotTypeResponse, ParkingSpotTypeSearchObject, ParkingSpotType, ParkingSpotTypeUpsertRequest, ParkingSpotTypeUpsertRequest>, IParkingSpotTypeService
    {
        public ParkingSpotTypeService(MoSmartParkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<ParkingSpotType> ApplyFilter(IQueryable<ParkingSpotType> query, ParkingSpotTypeSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(x => x.Name.Contains(search.FTS) || x.Description.Contains(search.FTS));
            }

            return query;
        }

        protected override async Task BeforeInsert(ParkingSpotType entity, ParkingSpotTypeUpsertRequest request)
        {
            if (await _context.ParkingSpotTypes.AnyAsync(p => p.Name == request.Name))
            {
                throw new InvalidOperationException("A parking spot type with this name already exists.");
            }
        }

        protected override async Task BeforeUpdate(ParkingSpotType entity, ParkingSpotTypeUpsertRequest request)
        {
            if (await _context.ParkingSpotTypes.AnyAsync(p => p.Name == request.Name && p.Id != entity.Id))
            {
                throw new InvalidOperationException("A parking spot type with this name already exists.");
            }
        }
    }
}

