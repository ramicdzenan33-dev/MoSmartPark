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
    public class ColorService : BaseCRUDService<ColorResponse, ColorSearchObject, Color, ColorUpsertRequest, ColorUpsertRequest>, IColorService
    {
        public ColorService(MoSmartParkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Color> ApplyFilter(IQueryable<Color> query, ColorSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(x => x.Name.Contains(search.FTS));
            }

            return query;
        }

        protected override async Task BeforeInsert(Color entity, ColorUpsertRequest request)
        {
            if (await _context.Colors.AnyAsync(c => c.Name == request.Name))
            {
                throw new InvalidOperationException("A color with this name already exists.");
            }
        }

        protected override async Task BeforeUpdate(Color entity, ColorUpsertRequest request)
        {
            if (await _context.Colors.AnyAsync(c => c.Name == request.Name && c.Id != entity.Id))
            {
                throw new InvalidOperationException("A color with this name already exists.");
            }
        }
    }
}

