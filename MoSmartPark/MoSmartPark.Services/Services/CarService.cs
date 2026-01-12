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
    public class CarService : BaseCRUDService<CarResponse, CarSearchObject, Car, CarUpsertRequest, CarUpsertRequest>, ICarService
    {
        public CarService(MoSmartParkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Car> ApplyFilter(IQueryable<Car> query, CarSearchObject search)
        {
            query = query.Include(c => c.Brand)
                         .Include(c => c.Color)
                         .Include(c => c.User);

            if (!string.IsNullOrEmpty(search.BrandModel))
            {
                query = query.Where(x => x.Model.Contains(search.BrandModel) || 
                                         (x.Brand != null && x.Brand.Name.Contains(search.BrandModel)));
            }

            if (!string.IsNullOrEmpty(search.LicensePlate))
            {
                query = query.Where(x => x.LicensePlate.Contains(search.LicensePlate));
            }

            if (search.BrandId.HasValue)
            {
                query = query.Where(x => x.BrandId == search.BrandId.Value);
            }

            if (search.ColorId.HasValue)
            {
                query = query.Where(x => x.ColorId == search.ColorId.Value);
            }

            if (search.UserId.HasValue)
            {
                query = query.Where(x => x.UserId == search.UserId.Value);
            }

            if (search.YearOfManufacture.HasValue)
            {
                query = query.Where(x => x.YearOfManufacture == search.YearOfManufacture.Value);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(x => x.IsActive == search.IsActive.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(x => x.Model.Contains(search.FTS) || 
                                         x.LicensePlate.Contains(search.FTS) ||
                                         (x.Brand != null && x.Brand.Name.Contains(search.FTS)));
            }

            return query;
        }

        protected override CarResponse MapToResponse(Car entity)
        {
            var response = _mapper.Map<CarResponse>(entity);
            if (entity.Brand != null)
            {
                response.BrandName = entity.Brand.Name;
                response.BrandLogo = entity.Brand.Logo;
            }
            if (entity.Color != null)
            {
                response.ColorName = entity.Color.Name;
                response.ColorHexCode = entity.Color.HexCode;
            }
            if (entity.User != null)
            {
                response.UserFullName = $"{entity.User.FirstName} {entity.User.LastName}";
            }
            return response;
        }

        protected override async Task BeforeInsert(Car entity, CarUpsertRequest request)
        {
            if (!await _context.Brands.AnyAsync(b => b.Id == request.BrandId))
            {
                throw new InvalidOperationException("The specified brand does not exist.");
            }

            if (!await _context.Colors.AnyAsync(c => c.Id == request.ColorId))
            {
                throw new InvalidOperationException("The specified color does not exist.");
            }

            if (!await _context.Users.AnyAsync(u => u.Id == request.UserId))
            {
                throw new InvalidOperationException("The specified user does not exist.");
            }
        }

        protected override async Task BeforeUpdate(Car entity, CarUpsertRequest request)
        {
            if (!await _context.Brands.AnyAsync(b => b.Id == request.BrandId))
            {
                throw new InvalidOperationException("The specified brand does not exist.");
            }

            if (!await _context.Colors.AnyAsync(c => c.Id == request.ColorId))
            {
                throw new InvalidOperationException("The specified color does not exist.");
            }

            if (!await _context.Users.AnyAsync(u => u.Id == request.UserId))
            {
                throw new InvalidOperationException("The specified user does not exist.");
            }
        }

        public override async Task<CarResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Cars
                .Include(c => c.Brand)
                .Include(c => c.Color)
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.Id == id);
            
            if (entity == null)
                return null;

            return MapToResponse(entity);
        }
    }
}

