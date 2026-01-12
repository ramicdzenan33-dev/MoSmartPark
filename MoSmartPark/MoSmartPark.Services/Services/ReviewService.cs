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
using MoSmartPark.Model;

namespace MoSmartPark.Services.Services
{
    public class ReviewService : BaseCRUDService<ReviewResponse, ReviewSearchObject, Review, ReviewUpsertRequest, ReviewUpsertRequest>, IReviewService
    {
        private ReviewSearchObject? _currentSearch;

        public ReviewService(MoSmartParkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<ReviewResponse>> GetAsync(ReviewSearchObject search)
        {
            var query = _context.Reviews
                .Include(r => r.User)
                .Include(r => r.Reservation)
                    .ThenInclude(res => res.Car)
                        .ThenInclude(car => car.Brand)
                .Include(r => r.Reservation)
                    .ThenInclude(res => res.ParkingSpot)
                .Include(r => r.Reservation)
                    .ThenInclude(res => res.ReservationType)
                .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                {
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                }
                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }

            _currentSearch = search;
            var list = await query.ToListAsync();
            var result = new PagedResult<ReviewResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
            _currentSearch = null;
            return result;
        }

        public override async Task<ReviewResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Reviews
                .Include(r => r.User)
                .Include(r => r.Reservation)
                    .ThenInclude(res => res.Car)
                        .ThenInclude(car => car.Brand)
                .Include(r => r.Reservation)
                    .ThenInclude(res => res.ParkingSpot)
                .Include(r => r.Reservation)
                    .ThenInclude(res => res.ReservationType)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
                return null;

            _currentSearch = new ReviewSearchObject { IncludePictures = true };
            var result = MapToResponse(entity);
            _currentSearch = null;
            return result;
        }

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchObject search)
        {
            if (search.UserId.HasValue)
            {
                query = query.Where(r => r.UserId == search.UserId.Value);
            }

            if (search.ReservationId.HasValue)
            {
                query = query.Where(r => r.ReservationId == search.ReservationId.Value);
            }

            if (search.Rating.HasValue)
            {
                query = query.Where(r => r.Rating == search.Rating.Value);
            }

            if (search.MinRating.HasValue)
            {
                query = query.Where(r => r.Rating >= search.MinRating.Value);
            }

            if (search.MaxRating.HasValue)
            {
                query = query.Where(r => r.Rating <= search.MaxRating.Value);
            }

            if (!string.IsNullOrEmpty(search.UserFullName))
            {
                query = query.Where(r => 
                    (r.User.FirstName + " " + r.User.LastName).Contains(search.UserFullName));
            }

            return query;
        }

        protected override ReviewResponse MapToResponse(Review entity)
        {
            var response = _mapper.Map<ReviewResponse>(entity);
            
            if (entity.User != null)
            {
                response.UserFullName = $"{entity.User.FirstName} {entity.User.LastName}";
                response.UserEmail = entity.User.Email;
                // Include user picture if IncludePictures is true
                if (_currentSearch?.IncludePictures != false && entity.User.Picture != null && entity.User.Picture.Length > 0)
                {
                    response.UserPicture = Convert.ToBase64String(entity.User.Picture);
                }
            }

            if (entity.Reservation != null)
            {
                if (entity.Reservation.Car != null)
                {
                    response.CarModel = entity.Reservation.Car.Model;
                    response.CarLicensePlate = entity.Reservation.Car.LicensePlate;
                    if (entity.Reservation.Car.Brand != null)
                    {
                        response.CarBrandName = entity.Reservation.Car.Brand.Name;
                    }
                    // Include car picture if IncludePictures is true
                    if (_currentSearch?.IncludePictures != false && entity.Reservation.Car.Picture != null && entity.Reservation.Car.Picture.Length > 0)
                    {
                        response.CarPicture = Convert.ToBase64String(entity.Reservation.Car.Picture);
                    }
                }
                
                if (entity.Reservation.ParkingSpot != null)
                {
                    response.ParkingSpotNumber = entity.Reservation.ParkingSpot.ParkingNumber;
                }
                
                if (entity.Reservation.ReservationType != null)
                {
                    response.ReservationTypeName = entity.Reservation.ReservationType.Name;
                }
                
                response.ReservationStartDate = entity.Reservation.StartDate;
                response.ReservationEndDate = entity.Reservation.EndDate;
                response.ReservationFinalPrice = entity.Reservation.FinalPrice;
            }

            return response;
        }

        protected override async Task BeforeInsert(Review entity, ReviewUpsertRequest request)
        {
            // Validate that user exists
            if (!await _context.Users.AnyAsync(u => u.Id == request.UserId))
            {
                throw new InvalidOperationException("User not found.");
            }

            // Validate that reservation exists
            if (!await _context.Reservations.AnyAsync(r => r.Id == request.ReservationId))
            {
                throw new InvalidOperationException("Reservation not found.");
            }

            // Check if user already reviewed this reservation
            if (await _context.Reviews.AnyAsync(r => r.UserId == request.UserId && r.ReservationId == request.ReservationId))
            {
                throw new InvalidOperationException("You have already reviewed this reservation.");
            }

            entity.CreatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeUpdate(Review entity, ReviewUpsertRequest request)
        {
            // Validate that user exists
            if (!await _context.Users.AnyAsync(u => u.Id == request.UserId))
            {
                throw new InvalidOperationException("User not found.");
            }

            // Validate that reservation exists
            if (!await _context.Reservations.AnyAsync(r => r.Id == request.ReservationId))
            {
                throw new InvalidOperationException("Reservation not found.");
            }

            // Check if another review by the same user for the same reservation exists (excluding current review)
            if (await _context.Reviews.AnyAsync(r => r.UserId == request.UserId && r.ReservationId == request.ReservationId && r.Id != entity.Id))
            {
                throw new InvalidOperationException("You have already reviewed this reservation.");
            }
        }
    }
}
