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
    public class ReservationTypeService : BaseCRUDService<ReservationTypeResponse, ReservationTypeSearchObject, ReservationType, ReservationTypeUpsertRequest, ReservationTypeUpsertRequest>, IReservationTypeService
    {
        public ReservationTypeService(MoSmartParkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<ReservationType> ApplyFilter(IQueryable<ReservationType> query, ReservationTypeSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            return query;
        }

        protected override async Task BeforeInsert(ReservationType entity, ReservationTypeUpsertRequest request)
        {
            if (await _context.ReservationTypes.AnyAsync(r => r.Name == request.Name))
            {
                throw new InvalidOperationException("A reservation type with this name already exists.");
            }
        }

        protected override async Task BeforeUpdate(ReservationType entity, ReservationTypeUpsertRequest request)
        {
            if (await _context.ReservationTypes.AnyAsync(r => r.Name == request.Name && r.Id != entity.Id))
            {
                throw new InvalidOperationException("A reservation type with this name already exists.");
            }
        }
    }
}
