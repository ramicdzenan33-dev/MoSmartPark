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
    public class BrandService : BaseCRUDService<BrandResponse, BrandSearchObject, Brand, BrandUpsertRequest, BrandUpsertRequest>, IBrandService
    {
        public BrandService(MoSmartParkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Brand> ApplyFilter(IQueryable<Brand> query, BrandSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(x => x.IsActive == search.IsActive.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(x => x.Name.Contains(search.FTS));
            }

            return query;
        }

        protected override async Task BeforeInsert(Brand entity, BrandUpsertRequest request)
        {
            if (await _context.Brands.AnyAsync(b => b.Name == request.Name))
            {
                throw new InvalidOperationException("A brand with this name already exists.");
            }
        }

        protected override async Task BeforeUpdate(Brand entity, BrandUpsertRequest request)
        {
            if (await _context.Brands.AnyAsync(b => b.Name == request.Name && b.Id != entity.Id))
            {
                throw new InvalidOperationException("A brand with this name already exists.");
            }
        }
    }
}

